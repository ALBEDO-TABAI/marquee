// SPDX-License-Identifier: AGPL-3.0-or-later

//! A clip carries two chains: `filters`, the FFmpeg audio filters, and
//! `videoEffects`, the picture's shader passes. The renderer reads each
//! for its own kind only, so a look written into `filters` (or a sound
//! filter into `videoEffects`) used to draw nothing and say nothing. A
//! caller of the API is told, and where the package's kind leaves no doubt
//! the link is moved to the chain that plays it.

use std::collections::BTreeMap;

use concat_effects::Catalogue;
use concat_effects::manifest::Kind;
use concat_project::Command;
use concat_project::model::{AppliedFilter, Project};

/// `command` with every misplaced link in an `updateClip` patch (nested
/// batches too) moved to the chain its package plays in, and a sentence
/// for each move or for a link that plays in neither.
pub(crate) fn route(command: Command, project: &Project) -> (Command, Vec<String>) {
    let mut notes = Vec::new();
    let mut seen = BTreeMap::new();
    let command = walk(command, project, &mut seen, &mut notes);
    (command, notes)
}

/// The chains as the batch has left them so far, by clip id.
type Chains = BTreeMap<String, (Vec<AppliedFilter>, Vec<AppliedFilter>)>;

fn walk(
    command: Command,
    project: &Project,
    seen: &mut Chains,
    notes: &mut Vec<String>,
) -> Command {
    match command {
        Command::Batch { commands } => Command::Batch {
            commands: commands
                .into_iter()
                .map(|command| walk(command, project, seen, notes))
                .collect(),
        },
        Command::UpdateClip { clip_id, mut patch } => {
            if patch.filters.is_some() || patch.video_effects.is_some() {
                let (filters, effects) = seen.get(&clip_id).cloned().unwrap_or_else(|| {
                    project
                        .active()
                        .clip(&clip_id)
                        .map(|clip| (clip.filters.clone(), clip.video_effects.clone()))
                        .unwrap_or_default()
                });
                let mut filters_out = patch.filters.clone();
                let mut effects_out = patch.video_effects.clone();
                if let Some(links) = patch.filters.take() {
                    let (kept, moved) = sort(links, &clip_id, "filters", notes, Kind::Audio);
                    filters_out = Some(kept);
                    if !moved.is_empty() {
                        let mut chain = effects_out.take().unwrap_or_else(|| effects.clone());
                        chain.extend(moved);
                        effects_out = Some(chain);
                    }
                }
                if let Some(links) = patch.video_effects.take() {
                    let links = effects_out.take().unwrap_or(links);
                    let (kept, moved) = sort(links, &clip_id, "videoEffects", notes, Kind::Effect);
                    effects_out = Some(kept);
                    if !moved.is_empty() {
                        let mut chain = filters_out.take().unwrap_or_else(|| filters.clone());
                        chain.extend(moved);
                        filters_out = Some(chain);
                    }
                }
                patch.filters = filters_out;
                patch.video_effects = effects_out;
                let entry = seen.entry(clip_id.clone()).or_insert((filters, effects));
                if let Some(chain) = &patch.filters {
                    entry.0 = chain.clone();
                }
                if let Some(chain) = &patch.video_effects {
                    entry.1 = chain.clone();
                }
            }
            Command::UpdateClip { clip_id, patch }
        }
        other => other,
    }
}

/// Splits one chain into the links that belong in it and the ones that
/// belong in the other chain. `home` is `Kind::Audio` for `filters` and
/// any picture kind for `videoEffects`.
fn sort(
    links: Vec<AppliedFilter>,
    clip_id: &str,
    chain: &str,
    notes: &mut Vec<String>,
    home: Kind,
) -> (Vec<AppliedFilter>, Vec<AppliedFilter>) {
    let catalogue = Catalogue::builtin();
    let (other, sound_chain) = if home == Kind::Audio {
        ("videoEffects", true)
    } else {
        ("filters", false)
    };
    let mut kept = Vec::new();
    let mut moved = Vec::new();
    for link in links {
        let Some(package) = catalogue.get(&link.id) else {
            notes.push(format!(
                "`{}` in {chain} on {clip_id} is not in the catalogue; it plays nothing",
                link.id
            ));
            kept.push(link);
            continue;
        };
        let kind = package.kind();
        let picture_look =
            matches!(kind, Kind::Effect | Kind::Filter) && package.shader().is_some();
        match (sound_chain, kind) {
            (true, Kind::Audio) | (false, Kind::Effect | Kind::Filter) => kept.push(link),
            (true, _) if picture_look => {
                notes.push(format!(
                    "`{}` is a picture effect, not an audio filter: moved from filters to videoEffects on {clip_id}",
                    link.id
                ));
                moved.push(link);
            }
            (false, Kind::Audio) => {
                notes.push(format!(
                    "`{}` is an audio filter, not a picture effect: moved from videoEffects to filters on {clip_id}",
                    link.id
                ));
                moved.push(link);
            }
            (_, kind) => {
                let instead = match kind {
                    Kind::Transition => "set it as the clip's transitionIn",
                    Kind::Sticker | Kind::Generator => "add it with addLayerClip",
                    Kind::Textanim => "set it as a title's animation",
                    _ => "it has no shader to draw",
                };
                notes.push(format!(
                    "`{}` in {chain} on {clip_id} is a {kind:?} package, which plays in neither {chain} nor {other}: {instead}",
                    link.id
                ));
                kept.push(link);
            }
        }
    }
    (kept, moved)
}
