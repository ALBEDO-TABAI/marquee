// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jareer Abdullah
//! Speech: voices and the lines read in them.

use super::*;

impl Studio {
    // ── speech ──

    /// Packs the open project into the template library.
    /// Where the user's own looks live: one package folder each.
    pub fn looks_dir(dirs: &concat_host::dirs::AppDirs) -> std::path::PathBuf {
        dirs.config.join("effects")
    }

    /// Where the effect cards are kept: drawn once, read on every launch.
    pub fn cards_dir(dirs: &concat_host::dirs::AppDirs) -> std::path::PathBuf {
        dirs.data.join("cards")
    }

    /// Plans every picture package's card against the catalogue as it
    /// stands, sweeps away the cards no package draws any more, and draws
    /// the missing ones on a thread of their own, on a compositor sharing
    /// the monitor's device - or, while a round is drawing already, asks
    /// for another when it ends.
    fn plan_cards(&mut self) {
        let dir = Self::cards_dir(&self.host.dirs);
        let cards = concat_host::cards::cards(Catalogue::builtin(), &dir);
        concat_host::cards::prune(&dir, &cards);
        self.card_paths = cards
            .iter()
            .map(|card| (card.id.clone(), card.path.clone()))
            .collect();
        let missing: Vec<concat_host::cards::Card> =
            cards.into_iter().filter(|card| !card.is_drawn()).collect();
        if missing.is_empty() {
            return;
        }
        if self.cards_busy {
            self.cards_again = true;
            return;
        }
        self.cards_busy = true;
        // On a thread of its own, so not on the window's device on Vulkan
        // (#324).
        let compositor = self.host.monitor.off_thread();
        let spawned = std::thread::Builder::new()
            .name("concat cards".to_owned())
            .spawn(move || {
                concat_host::cards::draw_all(&dir, &missing, compositor, |ids, done| {
                    crate::host::on_ui(move |studio, _, _| studio.cards_arrived(ids, done));
                });
            });
        if let Err(error) = spawned {
            log::warn!("cards: {error}");
            self.cards_busy = false;
        }
    }

    /// Cards have landed: `ids` are read again the next time the shelves
    /// are built. With `done` the round is over, and another is planned
    /// when the catalogue changed while it drew.
    fn cards_arrived(&mut self, ids: Vec<String>, done: bool) {
        {
            let mut art = self.look_art.borrow_mut();
            for id in &ids {
                art.remove(id);
            }
        }
        self.cards_drawn += ids.len() as u64;
        if done {
            self.cards_busy = false;
            if std::mem::take(&mut self.cards_again) {
                self.plan_cards();
            }
        }
    }

    /// Rebuilds the catalogue from the built-ins and the packages in
    /// `looks_dir`, and says in the window what would not load: the first
    /// reason and how many more, with every reason in the log, so an
    /// author sees a manifest or shader fault where they are looking
    /// rather than in a file they may not know exists. Returns how many
    /// failed. With `announce`, a clean reload is reported too, with the
    /// folder, which is how a newcomer learns where packages go.
    pub fn reload_packages(&mut self, announce: bool) -> usize {
        /// A custom package's shader runs once over a picture this many
        /// pixels a side before the package is offered: enough that a loop
        /// bounded in the thousands per pixel shows, and a real frame's
        /// worth of work does not.
        const TRIAL_SIDE: u32 = 512;
        /// How long that trial may take before the package is refused.
        const TRIAL_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(3);
        let dir = Self::looks_dir(&self.host.dirs);
        // Looks an earlier build imported, onto the format 2 look first.
        for id in concat_effects::looks::upgrade(&dir) {
            log::info!("{id}: the imported look now reads its table in light");
        }
        // The trials run on a compositor of their own on the window's
        // device, never the monitor's: one that times out is dead from
        // then on, and a refused package must not take the preview with
        // it (audit 2026-10-04, #6). A dead one is replaced for the next.
        let monitor = &self.host.monitor;
        let mut trialist = None;
        let errors = Catalogue::install_with(&dir, &mut |package| {
            for pass in package.trial_passes() {
                if trialist.is_none() {
                    trialist = monitor.sibling();
                }
                let Some(gpu) = trialist.as_mut() else {
                    return Ok(());
                };
                let tried = gpu.trial_at(&pass, TRIAL_SIDE, TRIAL_TIMEOUT);
                if gpu.is_dead() {
                    trialist = None;
                }
                if let Err(why) = tried {
                    return Err(format!("its shader failed its trial: {why}"));
                }
            }
            Ok(())
        });
        for error in &errors {
            log::warn!("package: {error}");
        }
        // Every picture package's card: those drawn before are read as the
        // shelves need them, the rest drawn on a thread of their own.
        self.plan_cards();
        // A changed shader means a changed card: the stills are read again.
        self.look_art.borrow_mut().clear();
        // The folder as the watch will next see it, cards included, so a
        // reload does not read as a change and set off another.
        self.packages_seen = concat_effects::package_stamp(&dir);
        self.packages_pending = None;
        if let Some(first) = errors.first() {
            let message = if errors.len() == 1 {
                tf("studio.customPackageDidNot", &[first])
            } else {
                tf("studio.customPackagesDidNot", &[&errors.len(), first])
            };
            self.notify(&message, true);
        } else if announce {
            let count = Catalogue::builtin()
                .packages()
                .filter(|package| package.folder.is_some())
                .count();
            self.notify(
                &tf("studio.loadedCustomPackagesFrom", &[&count, &dir.display()]),
                false,
            );
        }
        errors.len()
    }

    /// Starts the watch on the effects folder: a poll every two seconds,
    /// and a reload once two polls in a row see the same changed folder.
    /// A package written or dropped in while the app runs then shows up on
    /// its own, and one that will not load says why, without a restart or
    /// the button.
    pub fn watch_packages(&mut self) {
        self.packages_watch.start(
            slint::TimerMode::Repeated,
            std::time::Duration::from_secs(2),
            || {
                crate::host::Shell::with(|shell, app| {
                    let changed = shell.studio.borrow_mut().poll_packages();
                    if changed {
                        shell.studio.borrow_mut().refresh_art();
                        shell.studio.borrow().publish(&app, &shell.models);
                    }
                });
            },
        );
    }

    /// One tick of the watch: whether the catalogue was rebuilt.
    fn poll_packages(&mut self) -> bool {
        let now = concat_effects::package_stamp(&Self::looks_dir(&self.host.dirs));
        if now == self.packages_seen {
            self.packages_pending = None;
            return false;
        }
        if self.packages_pending != Some(now) {
            // Seen once; a copy may still be in progress. Next tick decides.
            self.packages_pending = Some(now);
            return false;
        }
        self.reload_packages(true);
        true
    }

    /// Asks for `.cube` files to import as looks. The dialog is asked with
    /// the studio unborrowed - on a phone it is the system's picker, which
    /// answers later - and the files come back to [`import_luts`]; see
    /// `host::pick_files_then`.
    ///
    /// [`import_luts`]: Studio::import_luts
    pub fn import_lut() {
        crate::host::pick_files_then(
            t("studio.importLut"),
            Some((t("studio.lut"), &["cube"])),
            |studio, _, _, paths| studio.import_luts(paths),
        );
    }

    /// Imports one or more `.cube` tables as looks: each becomes a package
    /// folder under `looks_dir` - a manifest that names the table, a shader
    /// that reads it, the table (see `concat_effects::looks`) - and the
    /// catalogue is rebuilt so the Adjustments page's LUTs shelf shows
    /// them, their cards drawn by their own shaders. Says how many arrived.
    pub fn import_luts(&mut self, paths: Vec<std::path::PathBuf>) {
        let dir = Self::looks_dir(&self.host.dirs);
        let mut imported = 0;
        for path in paths {
            match concat_effects::looks::import(&dir, &path) {
                Ok(id) => {
                    self.look_art.borrow_mut().remove(&id);
                    imported += 1;
                }
                Err(error) => {
                    self.notify(
                        &tf("studio.couldNotImport", &[&path.display(), &error]),
                        true,
                    );
                }
            }
        }
        if imported == 0 {
            return;
        }
        // A look that will not load has its reason on screen; the count of
        // the rest would only cover it.
        if self.reload_packages(false) > 0 {
            return;
        }
        self.notify(&tf("studio.importedLutsFindThem", &[&imported]), false);
    }

    /// The project's 素材 a pack's slots can take: every imported file
    /// with a path, as (kind, path, name).
    pub(crate) fn template_candidates(&self) -> Vec<(model::MediaKind, String, String)> {
        self.session
            .as_ref()
            .map(|session| {
                session
                    .project()
                    .media
                    .iter()
                    .filter(|item| !item.placeholder && !item.path.is_empty())
                    .map(|item| (item.kind, item.path.clone(), item.name.clone()))
                    .collect()
            })
            .unwrap_or_default()
    }

    /// The pack at `path`, with the 素材 that would fill each slot: the
    /// pick in the detail view when it is this pack's, the first unused
    /// fitting file in the bin otherwise.
    fn template_choices(
        &self,
        path: &str,
    ) -> Option<(templates::TemplateInfo, Vec<Option<usize>>)> {
        let info = templates::list(&self.host.dirs.config)
            .into_iter()
            .find(|item| item.path == path)?;
        let candidates = self.template_candidates();
        let choices = match &self.template_pick {
            Some(pick) if pick.path == path && pick.choices.len() == info.slots.len() => {
                pick.choices.clone()
            }
            _ => auto_choices(&info.slots, &candidates),
        };
        Some((info, choices))
    }

    /// Opens a pack's detail view: its preview, what each slot wants, and
    /// the 素材 matched to each so far.
    pub fn template_open(&mut self, path: String) {
        let Some((_, choices)) = self.template_choices(&path) else {
            return;
        };
        self.template_pick = Some(TemplatePick { path, choices });
    }

    pub fn template_close(&mut self) {
        self.template_pick = None;
    }

    /// The detail view's menu for slot `slot`: 0 for none, `n` for the
    /// n-th file that fits the slot.
    pub fn template_choose(&mut self, slot: usize, choice: usize) {
        let Some(pick) = self.template_pick.as_ref() else {
            return;
        };
        let path = pick.path.clone();
        let Some((info, mut choices)) = self.template_choices(&path) else {
            return;
        };
        let Some(wanted) = info.slots.get(slot) else {
            return;
        };
        let candidates = self.template_candidates();
        let fitting: Vec<usize> = (0..candidates.len())
            .filter(|index| slot_takes(wanted.kind, candidates[*index].0))
            .collect();
        choices[slot] = choice.checked_sub(1).and_then(|n| fitting.get(n).copied());
        self.template_pick = Some(TemplatePick { path, choices });
    }

    /// Applies a pack: with the detail view's picks when it is open on
    /// it, the bin's best matches otherwise. A slot still without a clip
    /// opens the detail view with that slot marked, rather than refusing.
    pub fn use_template(&mut self, path: String) {
        let Some(project_path) = self
            .session
            .as_ref()
            .map(|session| std::path::PathBuf::from(session.path()))
        else {
            return;
        };
        let Some((info, choices)) = self.template_choices(&path) else {
            self.notify(&t("mediaPane.noTemplatesYetMark"), true);
            return;
        };
        let missing: Vec<&str> = info
            .slots
            .iter()
            .zip(&choices)
            .filter(|(slot, choice)| choice.is_none() && !slot.optional)
            .map(|(slot, _)| slot.label.as_str())
            .collect();
        if !missing.is_empty() {
            self.notify(&tf("studio.templateNeedsSlots", &[&missing.join("、")]), false);
            self.template_pick = Some(TemplatePick { path, choices });
            return;
        }

        let candidates = self.template_candidates();
        let mut fills = Vec::new();
        for (slot, choice) in info.slots.iter().zip(&choices) {
            let Some(index) = choice else {
                continue; // an optional slot, left out
            };
            let Some((_, file, _)) = candidates.get(*index) else {
                continue;
            };
            match media::probe(file) {
                Ok(probed) => fills.push(templates::SlotFill {
                    media_id: slot.media_id.clone(),
                    item: probed.to_new_media(),
                }),
                Err(error) => {
                    self.notify(&error, true);
                    return;
                }
            }
        }

        let location = project_path
            .parent()
            .map(|parent| parent.to_path_buf())
            .unwrap_or_else(|| self.host.dirs.data.join("projects"));
        if let Err(error) = std::fs::create_dir_all(&location) {
            self.notify(&error.to_string(), true);
            return;
        }
        let mut name = info.name.clone();
        let mut n = 2;
        while location.join(&name).exists() {
            name = format!("{} {n}", info.name);
            n += 1;
        }

        match templates::instantiate(&path, &location.to_string_lossy(), &name, fills) {
            Ok(made) => {
                let shown = made.name.clone();
                self.template_pick = None;
                if let Err(error) = self.open_project(made) {
                    self.notify(&error, true);
                } else {
                    self.notify(&tf("studio.openedTemplate", &[&shown]), false);
                }
            }
            Err(error) => self.notify(&error, true),
        }
    }

    pub fn save_template(&mut self) {
        let Some(session) = self.session.as_ref() else {
            return;
        };
        let document = session.document();
        let settings = session.settings();
        let path = session.path().to_owned();
        let name = format!("{} template", self.project_name);
        let config = self.host.dirs.config.clone();
        spawn(
            move || templates::save(&config, &document, &settings, &path, &name),
            |studio, _, _, result| match result {
                Ok(info) => studio.notify(&tf("studio.savedTemplate", &[&info.name]), false),
                Err(error) => studio.notify(&error, true),
            },
        );
    }

    /// Whether a sheet covers the editor - Export, Settings, the project
    /// sheet, a relink, a question or the Voices shelf's New voice - so
    /// the editor's keys are not its own. The tool cards are not sheets:
    /// the timeline is worked beside them.
    pub fn sheet_open(&self) -> bool {
        self.export.open
            || self.settings.open
            || self.project_sheet.open
            || self.relink.open
            || self.confirm.is_some()
            || self.speech.new_voice.open
    }
}

/// A 智能包装 pack open in its detail view.
#[derive(Clone, Debug, PartialEq)]
pub(crate) struct TemplatePick {
    /// The bundle.
    pub path: String,
    /// Per slot, in the pack's order: which of the bin's files fills it
    /// (an index into `template_candidates`), or none yet.
    pub choices: Vec<Option<usize>>,
}

/// Whether a slot of `slot` kind takes a file of `file` kind: music for
/// the music, a video or a photo for a shot.
pub(crate) fn slot_takes(slot: model::MediaKind, file: model::MediaKind) -> bool {
    match slot {
        model::MediaKind::Audio => file == model::MediaKind::Audio,
        _ => matches!(file, model::MediaKind::Video | model::MediaKind::Image),
    }
}

/// The bin's first fitting file for each slot in turn, each file used
/// once; a video before a photo for a shot, as the pack was cut for one.
pub(crate) fn auto_choices(
    slots: &[templates::SlotInfo],
    candidates: &[(model::MediaKind, String, String)],
) -> Vec<Option<usize>> {
    let mut taken = vec![false; candidates.len()];
    slots
        .iter()
        .map(|slot| {
            let pick = |kind: Option<model::MediaKind>| {
                (0..candidates.len()).find(|index| {
                    !taken[*index]
                        && slot_takes(slot.kind, candidates[*index].0)
                        && kind.is_none_or(|kind| candidates[*index].0 == kind)
                })
            };
            let found = pick(Some(slot.kind)).or_else(|| pick(None));
            if let Some(index) = found {
                taken[index] = true;
            }
            found
        })
        .collect()
}

#[cfg(test)]
mod template_tests {
    use super::*;
    use model::MediaKind;

    fn slot(label: &str, kind: MediaKind, optional: bool) -> templates::SlotInfo {
        templates::SlotInfo {
            media_id: label.to_owned(),
            name: label.to_owned(),
            kind,
            seconds: 3.0,
            label: label.to_owned(),
            hint: String::new(),
            optional,
            orientation: None,
        }
    }

    fn file(kind: MediaKind, name: &str) -> (MediaKind, String, String) {
        (kind, format!("/media/{name}"), name.to_owned())
    }

    /// Each slot takes the first unused file that fits it: a video for a
    /// shot before a photo, music only for the music, nothing when the bin
    /// has run out - left for the detail view to ask about.
    #[test]
    fn the_bin_is_matched_to_the_slots_in_order() {
        let slots = [
            slot("开场横拍", MediaKind::Video, false),
            slot("人物口播", MediaKind::Video, false),
            slot("结尾空镜", MediaKind::Video, false),
            slot("配乐", MediaKind::Audio, true),
        ];
        let bin = [
            file(MediaKind::Image, "photo.jpg"),
            file(MediaKind::Audio, "song.m4a"),
            file(MediaKind::Video, "a.mp4"),
        ];
        assert_eq!(
            auto_choices(&slots, &bin),
            [Some(2), Some(0), None, Some(1)]
        );
        assert_eq!(auto_choices(&slots, &[]), [None, None, None, None]);
    }

    #[test]
    fn a_shot_takes_a_video_or_a_photo_and_the_music_takes_sound() {
        assert!(slot_takes(MediaKind::Video, MediaKind::Image));
        assert!(slot_takes(MediaKind::Video, MediaKind::Video));
        assert!(!slot_takes(MediaKind::Video, MediaKind::Audio));
        assert!(slot_takes(MediaKind::Audio, MediaKind::Audio));
        assert!(!slot_takes(MediaKind::Audio, MediaKind::Video));
    }
}
