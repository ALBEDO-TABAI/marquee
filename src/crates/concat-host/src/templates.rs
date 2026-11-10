// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jareer Abdullah

//! Template bundles on disk.
//!
//! A template is a folder in the app config directory's `templates/`:
//!
//! - `template.json` - an ordinary project document whose placeholder media
//!   (engine `placeholder: true`) have blank paths, and whose bundled media
//!   and fonts - the music, overlays and faces that are part of the design -
//!   have paths relative to the bundle (`assets/...`).
//! - `assets/` - those bundled files, copied in at save time.
//! - `poster.jpg` - a frame of the edit, for the gallery card. A built-in
//!   pack's is drawn from the pack itself with the neutral card still in
//!   every picture slot ([`preview_frames`]), the same render its hover
//!   plays live.
//!
//! A bundle may say what each slot is for, beside the document:
//! `marqueePack.slots` is a list of `{ media, label, hint, optional }`, one
//! per placeholder it names - `label` the shot in a word (开场横拍), `hint`
//! what to put there, `optional` a slot the edit stands without (the music).
//!
//! Saving packs the open project into a bundle; instantiating unpacks one
//! into a fresh project folder and fills every slot with the user's media
//! *through the engine* (`Command::FillSlot` in a batch), so what a fill
//! means is defined in exactly one place - `concat-project` - and the editor
//! never opens on a slot with a dead path.

use std::path::{Path, PathBuf};

use concat_project::{Command, DocumentSettings, Editor};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::{media, projects};

const MANIFEST: &str = "template.json";
const ASSETS: &str = "assets";
const POSTER: &str = "poster.jpg";

/// One template, as the gallery sees it.
#[cfg_attr(feature = "schema", derive(schemars::JsonSchema))]
#[derive(Serialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct TemplateInfo {
    /// The bundle folder.
    pub path: String,
    /// The template's name.
    pub name: String,
    /// Output width in pixels.
    pub width: u32,
    /// Output height in pixels.
    pub height: u32,
    /// Frame rate numerator.
    pub rate_num: i64,
    /// Frame rate denominator.
    pub rate_den: i64,
    /// The slots to fill, in the order they first appear on the timeline.
    pub slots: Vec<SlotInfo>,
    /// Whether the bundle carries a poster.
    pub has_poster: bool,
    /// The pack's shelf, for a built-in one; empty for a saved template.
    pub category: String,
    /// What the pack does, in a line; empty when it does not say.
    pub note: String,
    /// The edit's length in seconds: where its last clip ends.
    pub seconds: f64,
}

/// Which way a picture slot's frame runs: the template's own shape.
#[cfg_attr(feature = "schema", derive(schemars::JsonSchema))]
#[derive(Serialize, Clone, Copy, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub enum Orientation {
    /// Wider than tall.
    Landscape,
    /// Taller than wide.
    Portrait,
    /// As wide as tall.
    Square,
}

impl Orientation {
    /// The shape of a `width` × `height` frame.
    pub fn of(width: u32, height: u32) -> Orientation {
        match width.cmp(&height) {
            std::cmp::Ordering::Greater => Orientation::Landscape,
            std::cmp::Ordering::Less => Orientation::Portrait,
            std::cmp::Ordering::Equal => Orientation::Square,
        }
    }
}

/// One placeholder the user's media will replace.
#[cfg_attr(feature = "schema", derive(schemars::JsonSchema))]
#[derive(Serialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct SlotInfo {
    /// The placeholder media's id in the template document.
    pub media_id: String,
    /// The placeholder's name, as the creator labelled it.
    pub name: String,
    /// What kind of media the slot wants.
    pub kind: concat_project::model::MediaKind,
    /// Timeline seconds this slot covers, summed over its clips.
    pub seconds: f64,
    /// What the shot is, in a word (开场横拍): the bundle's own label, or
    /// the placeholder's name when it gives none.
    pub label: String,
    /// What to put there, when the bundle says; empty otherwise.
    pub hint: String,
    /// Whether the edit stands without it: an unfilled optional slot's
    /// clips are left out of the project rather than refusing it.
    pub optional: bool,
    /// The frame a picture slot fills, so a clip shot the same way fits
    /// it; none for sound.
    pub orientation: Option<Orientation>,
}

/// The user's media for one slot, straight from a probe.
#[derive(Deserialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct SlotFill {
    /// Which slot.
    pub media_id: String,
    /// What fills it.
    pub item: concat_project::commands::NewMedia,
}

/// Where the library lives under the config directory.
pub fn templates_dir(config: &Path) -> PathBuf {
    config.join("templates")
}

/// Packs the given document into a new template bundle.
///
/// `project_path` is where the document's media paths currently resolve; it
/// also donates the poster frame. Refuses a name that already exists rather
/// than overwriting someone's work.
pub fn save(
    config: &Path,
    document: &Value,
    settings: &DocumentSettings,
    project_path: &str,
    name: &str,
) -> Result<TemplateInfo, String> {
    let root = templates_dir(config).join(projects::folder_name(name));
    if root.join(MANIFEST).exists() {
        return Err(format!("a template named {name:?} already exists"));
    }
    let assets = root.join(ASSETS);
    std::fs::create_dir_all(&assets)
        .map_err(|error| format!("could not create {}: {error}", assets.display()))?;

    // Typed through the engine's reader and writer, not hand-edited JSON:
    // the manifest is written by the same code path every save uses, and a
    // schema change breaks this at compile time.
    let Some(mut project) = concat_project::from_document(document) else {
        return Err("the open project is not a document this build can read".to_owned());
    };

    // Placeholder media loses its path - it was the creator's own footage,
    // standing in. Everything else is part of the design and ships in the
    // bundle, referenced relative to it.
    for item in &mut project.media {
        if item.placeholder {
            item.path = String::new();
            continue;
        }
        item.path = bundle_file(&assets, &item.id.clone(), &item.path.clone())?;
    }
    for (index, font) in project.fonts.iter_mut().enumerate() {
        font.path = bundle_file(&assets, &format!("font{index}"), &font.path.clone())?;
    }

    let mut settings = settings.clone();
    settings.name = name.to_owned();
    let document = concat_project::to_document(&settings, &project);

    let encoded = serde_json::to_vec_pretty(&document)
        .map_err(|error| format!("could not encode the template: {error}"))?;
    std::fs::write(root.join(MANIFEST), encoded)
        .map_err(|error| format!("could not write the template: {error}"))?;

    // Best effort: a template without a poster is still a template.
    if let Ok(bytes) = media::poster_frame(project_path) {
        let _ = std::fs::write(root.join(POSTER), bytes);
    }

    read_info(&root)
}

/// Copies one source file into `assets/` and returns its bundle-relative
/// path. The bundle must be self-contained, so a missing source is an error,
/// not a warning - a template that cannot find its own music is not one.
fn bundle_file(assets: &Path, id: &str, source: &str) -> Result<String, String> {
    if source.is_empty() {
        return Err(
            "a media item has no file behind it; fill or remove it before saving a template"
                .to_owned(),
        );
    }
    let base = Path::new(source)
        .file_name()
        .and_then(|name| name.to_str())
        .map(projects::folder_name)
        .unwrap_or_else(|| "file".to_owned());
    let name = format!("{}-{base}", projects::folder_name(id));
    let destination = assets.join(&name);
    std::fs::copy(source, &destination)
        .map_err(|error| format!("could not bundle {source}: {error}"))?;
    Ok(format!("{ASSETS}/{name}"))
}

/// Every template in the library, in name order.
///
/// A folder that does not parse is skipped rather than sinking the whole
/// gallery - the same grace the recents list extends to vanished projects.
fn list_from(dir: &Path) -> Vec<TemplateInfo> {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return Vec::new();
    };
    entries
        .filter_map(|entry| entry.ok())
        .filter_map(|entry| read_info(&entry.path()).ok())
        .collect()
}

/// Built-in 智能包装 recipes shipped beside this crate.
pub fn builtin_smart_packs_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("smart-packs")
}

/// Every template in the library, user-saved and the built-in 智能包装
/// recipes, in name order.
pub fn list(config: &Path) -> Vec<TemplateInfo> {
    let mut templates = list_from(&templates_dir(config));
    templates.extend(list_from(&builtin_smart_packs_dir()));
    templates.sort_by(|left, right| left.name.cmp(&right.name));
    templates
}

/// Reads one bundle's manifest into gallery form.
fn read_info(root: &Path) -> Result<TemplateInfo, String> {
    let manifest = root.join(MANIFEST);
    let bytes = std::fs::read(&manifest)
        .map_err(|error| format!("could not read {}: {error}", manifest.display()))?;
    let document: Value = serde_json::from_slice(&bytes)
        .map_err(|error| format!("{} is not a template: {error}", manifest.display()))?;

    let video = document
        .get("video")
        .ok_or("the template names no output format")?;
    let dimension = |field: &str| {
        video
            .get(field)
            .and_then(Value::as_u64)
            .and_then(|value| u32::try_from(value).ok())
            .filter(|value| *value > 0)
            .ok_or_else(|| format!("the template has no usable {field}"))
    };
    let rate = |field: &str| {
        video
            .get(field)
            .and_then(Value::as_i64)
            .filter(|value| *value > 0)
            .ok_or_else(|| format!("the template has no usable {field}"))
    };

    Ok(TemplateInfo {
        path: root.to_string_lossy().into_owned(),
        name: document
            .get("name")
            .and_then(Value::as_str)
            .unwrap_or("Template")
            .to_owned(),
        width: dimension("width")?,
        height: dimension("height")?,
        rate_num: rate("rateNum")?,
        rate_den: rate("rateDen")?,
        slots: slots_of(&document),
        has_poster: root.join(POSTER).exists(),
        category: pack_text(&document, "category"),
        note: pack_text(&document, "note"),
        seconds: concat_project::from_document(&document)
            .map(|project| {
                let timeline = project
                    .timelines
                    .iter()
                    .find(|timeline| timeline.id == project.active_timeline_id)
                    .or_else(|| project.timelines.first());
                timeline
                    .map(|timeline| {
                        timeline
                            .clips
                            .iter()
                            .map(|clip| clip.start + clip.duration)
                            .fold(0.0, f64::max)
                    })
                    .unwrap_or(0.0)
            })
            .unwrap_or(0.0),
    })
}

/// One of the `marqueePack` strings, or empty.
fn pack_text(document: &Value, field: &str) -> String {
    document
        .get("marqueePack")
        .and_then(|pack| pack.get(field))
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_owned()
}

/// What `marqueePack.slots` says about one placeholder, if anything:
/// `(label, hint, optional)`.
fn slot_guide(document: &Value, media_id: &str) -> Option<(String, String, bool)> {
    let entry = document
        .get("marqueePack")?
        .get("slots")?
        .as_array()?
        .iter()
        .find(|entry| entry.get("media").and_then(Value::as_str) == Some(media_id))?;
    let text = |field: &str| {
        entry
            .get(field)
            .and_then(Value::as_str)
            .unwrap_or("")
            .trim()
            .to_owned()
    };
    Some((
        text("label"),
        text("hint"),
        entry.get("optional").and_then(Value::as_bool).unwrap_or(false),
    ))
}

/// The placeholder media of a document, ordered by when each first appears
/// on the active timeline - the order a user fills them in.
///
/// Typed through the engine's own reader: a schema change breaks this at
/// compile time, not as a gallery that silently shows no slots.
fn slots_of(document: &Value) -> Vec<SlotInfo> {
    let Some(project) = concat_project::from_document(document) else {
        return Vec::new();
    };
    let clips = project
        .timelines
        .iter()
        .find(|timeline| timeline.id == project.active_timeline_id)
        .or_else(|| project.timelines.first())
        .map(|timeline| timeline.clips.as_slice())
        .unwrap_or(&[]);

    let shape = Orientation::of(project.active().video.width.max(1), project.active().video.height.max(1));
    let mut slots: Vec<(f64, SlotInfo)> = Vec::new();
    for item in &project.media {
        if !item.placeholder {
            continue;
        }

        let mut first = f64::MAX;
        let mut seconds = 0.0;
        for clip in clips.iter().filter(|clip| clip.media_id == item.id) {
            first = first.min(clip.start);
            seconds += clip.duration;
        }

        let (label, hint, optional) = slot_guide(document, &item.id).unwrap_or_default();
        slots.push((
            first,
            SlotInfo {
                media_id: item.id.clone(),
                name: item.name.clone(),
                kind: item.kind,
                seconds,
                label: if label.is_empty() { item.name.clone() } else { label },
                hint,
                optional,
                orientation: (item.kind != concat_project::model::MediaKind::Audio).then_some(shape),
            },
        ));
    }
    // The shots in the order they play, then the sound: the music runs
    // under all of them and is the one a user may leave out.
    slots.sort_by(|(left, a), (right, b)| {
        let sound = |slot: &SlotInfo| slot.kind == concat_project::model::MediaKind::Audio;
        sound(a).cmp(&sound(b)).then(left.total_cmp(right))
    });
    slots.into_iter().map(|(_, slot)| slot).collect()
}

/// Unpacks a template into a fresh project with every slot filled.
///
/// The fills go through the engine as one `Batch` of `FillSlot` commands, so
/// the semantics live in `concat-project` and a half-fillable set of media
/// leaves no half-made project behind.
pub fn instantiate(
    template: &str,
    location: &str,
    name: &str,
    fills: Vec<SlotFill>,
) -> Result<projects::ProjectInfo, String> {
    let bundle = PathBuf::from(template);
    let manifest = bundle.join(MANIFEST);
    let bytes = std::fs::read(&manifest)
        .map_err(|error| format!("could not read {}: {error}", manifest.display()))?;
    let mut document: Value = serde_json::from_slice(&bytes)
        .map_err(|error| format!("{} is not a template: {error}", manifest.display()))?;
    let info = read_info(&bundle)?;

    let unfilled: Vec<&SlotInfo> = info
        .slots
        .iter()
        .filter(|slot| !fills.iter().any(|fill| fill.media_id == slot.media_id))
        .collect();
    let needed: Vec<&str> = unfilled
        .iter()
        .filter(|slot| !slot.optional)
        .map(|slot| slot.label.as_str())
        .collect();
    if !needed.is_empty() {
        return Err(format!(
            "{} slot(s) still need a clip: {}",
            needed.len(),
            needed.join(", ")
        ));
    }
    // An optional slot left empty - the music, say - goes, clips and all,
    // so the project opens without a dead path in it.
    let dropped: Vec<String> = unfilled.iter().map(|slot| slot.media_id.clone()).collect();
    drop_slots(&mut document, &dropped);

    let project = projects::create(
        location,
        name,
        info.width,
        info.height,
        info.rate_num,
        info.rate_den,
        [0, 0, 0, 255],
    )?;
    let root = PathBuf::from(&project.path);

    // The bundle's assets move into the project so it stands alone; the
    // document's relative paths become project-local absolute ones.
    copy_assets(&bundle.join(ASSETS), &root.join(ASSETS))?;
    document["name"] = Value::String(project.name.clone());
    for section in ["media", "fonts"] {
        if let Some(items) = document.get_mut(section).and_then(Value::as_array_mut) {
            for item in items {
                let Some(path) = item.get("path").and_then(Value::as_str) else {
                    continue;
                };
                if let Some(relative) = path.strip_prefix(&format!("{ASSETS}/")) {
                    let absolute = root.join(ASSETS).join(relative);
                    item["path"] = Value::String(absolute.to_string_lossy().into_owned());
                }
            }
        }
    }

    let mut editor = Editor::from_document(&document)
        .ok_or("this template holds a document this build cannot read")?;
    // A template saved before an effect was retired opens the way a
    // project does: its links read as links to the stand-ins.
    let catalogue = concat_effects::Catalogue::builtin();
    editor.upgrade_links(|link| catalogue.upgrade(link));
    editor.upgrade_mask_effects();
    if !fills.is_empty() {
        editor
            .apply(Command::Batch {
                commands: fills
                    .into_iter()
                    .map(|fill| Command::FillSlot {
                        media_id: fill.media_id,
                        item: fill.item,
                    })
                    .collect(),
            })
            .map_err(|error| format!("could not fill the template: {error}"))?;
    }

    let settings = DocumentSettings {
        name: project.name.clone(),
        width: info.width,
        height: info.height,
        rate_num: info.rate_num,
        rate_den: info.rate_den,
        canvas: editor.project().active().video.canvas,
    };
    projects::save(&project.path, &editor.to_document(&settings))?;

    // After the save, so the cached poster reads as fresh.
    if bundle.join(POSTER).is_file() {
        let cache = root.join("cache");
        let _ = std::fs::create_dir_all(&cache);
        let _ = std::fs::copy(bundle.join(POSTER), cache.join("preview.jpg"));
    }

    Ok(project)
}

/// Takes the placeholders `ids` out of a document, and every clip that
/// shows one.
fn drop_slots(document: &mut Value, ids: &[String]) {
    if ids.is_empty() {
        return;
    }
    let named = |value: &Value, field: &str| {
        value
            .get(field)
            .and_then(Value::as_str)
            .is_some_and(|id| ids.iter().any(|gone| gone == id))
    };
    if let Some(media) = document.get_mut("media").and_then(Value::as_array_mut) {
        media.retain(|item| !named(item, "id"));
    }
    let mut clip_lists: Vec<&mut Vec<Value>> = Vec::new();
    if let Some(Value::Array(clips)) = document.get_mut("clips") {
        clip_lists.push(clips);
    }
    for list in clip_lists {
        list.retain(|clip| !named(clip, "mediaId"));
    }
    if let Some(timelines) = document.get_mut("timelines").and_then(Value::as_array_mut) {
        for timeline in timelines {
            if let Some(clips) = timeline.get_mut("clips").and_then(Value::as_array_mut) {
                clips.retain(|clip| !named(clip, "mediaId"));
            }
        }
    }
}

/// The square still every built-in pack's poster and hover are drawn
/// with: the shelf cards' own picture, in every picture slot, so a pack
/// shows its titles, cuts and looks on something neutral.
pub fn placeholder_still() -> Result<PathBuf, String> {
    let path = std::env::temp_dir().join("marquee-card-still.jpg");
    if !path.is_file() {
        std::fs::write(&path, crate::cards::STILL).map_err(|error| error.to_string())?;
    }
    Ok(path)
}

/// The instants a pack's hover plays, in seconds: `count` of them spread
/// over the edit, a little in from each end.
pub fn preview_times(seconds: f64, count: usize) -> Vec<f64> {
    let span = seconds.max(0.1);
    (0..count)
        .map(|n| span * (n as f64 + 0.5) / count.max(1) as f64)
        .collect()
}

/// Where a pack's poster is taken: a third of the way in, past the
/// title's entrance and on the first shot.
pub fn poster_time(seconds: f64) -> f64 {
    (seconds.max(0.1) / 3.0).min(2.0)
}

/// The size a pack's poster and hover are drawn at: 480 on the long side,
/// the template's shape, even.
pub fn preview_size(width: u32, height: u32) -> (u32, u32) {
    let long = width.max(height).max(1) as f64;
    let even = |side: u32| ((side as f64 * 480.0 / long).round() as u32 / 2 * 2).max(2);
    (even(width), even(height))
}

/// A pack's own edit, drawn at `times` with the neutral still in every
/// picture slot and its optional slots left out: the frames its card and
/// hover show. RGBA, `preview_size` each.
pub fn preview_frames(
    template: &str,
    times: &[f64],
    pool: &concat_media::ReaderPool,
) -> Result<Vec<concat_core::frame::Frame>, String> {
    preview_frames_until(template, times, pool, &|| false)
}

/// A pack's hover: `count` frames over its whole edit, drawn as
/// [`preview_frames`] draws its poster. Stops, with "cancelled", once
/// `stop` says the pointer has moved on.
pub fn hover_frames(
    template: &str,
    count: usize,
    pool: &concat_media::ReaderPool,
    stop: &dyn Fn() -> bool,
) -> Result<Vec<concat_core::frame::Frame>, String> {
    let info = read_info(Path::new(template))?;
    preview_frames_until(template, &preview_times(info.seconds, count), pool, stop)
}

fn preview_frames_until(
    template: &str,
    times: &[f64],
    pool: &concat_media::ReaderPool,
    stop: &dyn Fn() -> bool,
) -> Result<Vec<concat_core::frame::Frame>, String> {
    let bundle = PathBuf::from(template);
    let manifest = bundle.join(MANIFEST);
    let bytes = std::fs::read(&manifest)
        .map_err(|error| format!("could not read {}: {error}", manifest.display()))?;
    let mut document: Value = serde_json::from_slice(&bytes)
        .map_err(|error| format!("{} is not a template: {error}", manifest.display()))?;
    let info = read_info(&bundle)?;
    let still = placeholder_still()?;

    // Bundled assets are read where they are.
    for section in ["media", "fonts"] {
        if let Some(items) = document.get_mut(section).and_then(Value::as_array_mut) {
            for item in items {
                let Some(path) = item.get("path").and_then(Value::as_str) else {
                    continue;
                };
                if let Some(relative) = path.strip_prefix(&format!("{ASSETS}/")) {
                    let absolute = bundle.join(ASSETS).join(relative);
                    item["path"] = Value::String(absolute.to_string_lossy().into_owned());
                }
            }
        }
    }
    let sound: Vec<String> = info
        .slots
        .iter()
        .filter(|slot| slot.kind == concat_project::model::MediaKind::Audio)
        .map(|slot| slot.media_id.clone())
        .collect();
    drop_slots(&mut document, &sound);
    // The still is square: each shot's clip is scaled up to cover the
    // frame, so the card shows a picture edge to edge, not a square in
    // bars.
    let cover = f64::from(info.width.max(info.height)) / f64::from(info.width.min(info.height).max(1));
    let pictures: Vec<&str> = info
        .slots
        .iter()
        .filter(|slot| slot.kind != concat_project::model::MediaKind::Audio)
        .map(|slot| slot.media_id.as_str())
        .collect();
    let mut clip_lists: Vec<&mut Vec<Value>> = Vec::new();
    if let Some(Value::Array(clips)) = document.get_mut("clips") {
        clip_lists.push(clips);
    }
    for clips in clip_lists {
        for clip in clips.iter_mut() {
            let shows = clip
                .get("mediaId")
                .and_then(Value::as_str)
                .is_some_and(|id| pictures.contains(&id));
            if shows {
                let scale = clip.get("scale").and_then(Value::as_f64).unwrap_or(1.0);
                clip["scale"] = Value::from(scale * cover);
            }
        }
    }

    let mut editor = Editor::from_document(&document)
        .ok_or("this template holds a document this build cannot read")?;
    let catalogue = concat_effects::Catalogue::builtin();
    editor.upgrade_links(|link| catalogue.upgrade(link));
    editor.upgrade_mask_effects();
    let fills: Vec<Command> = info
        .slots
        .iter()
        .filter(|slot| slot.kind != concat_project::model::MediaKind::Audio)
        .map(|slot| Command::FillSlot {
            media_id: slot.media_id.clone(),
            item: concat_project::commands::NewMedia {
                path: still.to_string_lossy().into_owned(),
                name: slot.label.clone(),
                duration: None,
                kind: concat_project::model::MediaKind::Image,
                width: Some(crate::cards::WIDTH),
                height: Some(crate::cards::HEIGHT),
                frame_rate: None,
                frame_rate_fraction: None,
                video_codec: None,
                audio_codec: None,
                has_audio: false,
                audio_tracks: Vec::new(),
                origin: None,
                color_space: Default::default(),
            },
        })
        .collect();
    if !fills.is_empty() {
        editor
            .apply(Command::Batch { commands: fills })
            .map_err(|error| format!("could not fill the template: {error}"))?;
    }

    let project = editor.project();
    let (width, height) = preview_size(info.width, info.height);
    let mut clips = concat_export::flatten::flatten_timeline(project, None);
    // The titles and shapes, painted as the export paints them, in a
    // scratch folder of the pack preview's own.
    let scratch = std::env::temp_dir().join("marquee-pack-preview");
    let titles = crate::titles::Titles::new(&crate::dirs::AppDirs {
        config: scratch.clone(),
        data: scratch,
    });
    clips.extend(
        titles
            .clips(project, info.width, info.height)
            .into_iter()
            .map(|title| title.clip),
    );
    times
        .iter()
        .map(|&time| {
            if stop() {
                return Err("cancelled".to_owned());
            }
            let request = concat_export::PreviewFrameRequest {
                time,
                width,
                height,
                rate_num: info.rate_num,
                rate_den: info.rate_den,
                clips: clips.clone(),
                color_space: project.active().video.color_space,
                canvas: project.active().video.canvas,
            };
            let pixels = concat_export::preview_frame(pool, &request)?;
            concat_core::frame::Frame::from_rgba(width, height, pixels)
                .ok_or_else(|| "a preview frame of the wrong size".to_owned())
        })
        .collect()
}

fn copy_assets(from: &Path, to: &Path) -> Result<(), String> {
    let Ok(entries) = std::fs::read_dir(from) else {
        return Ok(()); // a template with no bundled assets
    };
    std::fs::create_dir_all(to)
        .map_err(|error| format!("could not create {}: {error}", to.display()))?;
    for entry in entries.filter_map(|entry| entry.ok()) {
        let source = entry.path();
        if source.is_file() {
            let destination = to.join(entry.file_name());
            std::fs::copy(&source, &destination)
                .map_err(|error| format!("could not copy {}: {error}", source.display()))?;
        }
    }
    Ok(())
}

/// Removes one template bundle for good.
///
/// Only ever a folder inside the templates directory that actually holds a
/// manifest - this function deletes recursively, and a stray path here would
/// be a catastrophe, so it is checked rather than trusted.
pub fn delete(config: &Path, path: &str) -> Result<(), String> {
    let target = PathBuf::from(path);
    let library = templates_dir(config);
    let (Ok(target), Ok(library)) = (target.canonicalize(), library.canonicalize()) else {
        return Err(format!("{path} is not a template"));
    };
    if !target.starts_with(&library) || target == library || !target.join(MANIFEST).is_file() {
        return Err(format!("{path} is not a template"));
    }
    std::fs::remove_dir_all(&target)
        .map_err(|error| format!("could not delete {}: {error}", target.display()))
}

/// The poster bytes for one bundle, or an error the caller treats as "no art".
pub fn poster(path: &str) -> Result<Vec<u8>, String> {
    std::fs::read(Path::new(path).join(POSTER))
        .map_err(|error| format!("no poster for {path}: {error}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use concat_project::model::MediaKind;
    use serde_json::json;

    fn template_document() -> Value {
        json!({
            "concat": "0.1.0", "version": 1, "name": "Beat Intro",
            "video": { "width": 1920, "height": 1080, "rateNum": 30, "rateDen": 1 },
            "media": [
                { "id": "m1", "path": "", "name": "A-roll", "duration": 4.0, "kind": "video",
                  "hasAudio": true, "placeholder": true },
                { "id": "m2", "path": "", "name": "B-roll", "duration": 2.0, "kind": "video",
                  "hasAudio": false, "placeholder": true }
            ],
            "tracks": [{ "id": "T1", "name": "Track 1", "visible": true, "muted": false }],
            "clips": [
                { "id": "c2", "trackId": "T1", "mediaId": "m2", "name": "B-roll",
                  "kind": "video", "start": 4.0, "duration": 2.0, "sourceStart": 0.0,
                  "volume": 1.0, "fadeIn": 0.0, "fadeOut": 0.0, "scale": 1.0,
                  "offsetX": 0.0, "offsetY": 0.0, "rotation": 0.0, "opacity": 1.0,
                  "speed": 1.0, "preservePitch": true, "filters": [], "videoEffects": [] },
                { "id": "c1", "trackId": "T1", "mediaId": "m1", "name": "A-roll",
                  "kind": "video", "start": 0.0, "duration": 4.0, "sourceStart": 1.0,
                  "volume": 1.0, "fadeIn": 0.0, "fadeOut": 0.0, "scale": 1.0,
                  "offsetX": 0.0, "offsetY": 0.0, "rotation": 0.0, "opacity": 1.0,
                  "speed": 1.0, "preservePitch": true, "filters": [], "videoEffects": [] }
            ]
        })
    }

    fn fill(media_id: &str, path: &str, duration: f64) -> SlotFill {
        SlotFill {
            media_id: media_id.to_owned(),
            item: concat_project::commands::NewMedia {
                path: path.to_owned(),
                name: path.rsplit('/').next().unwrap_or(path).to_owned(),
                duration: Some(duration),
                kind: MediaKind::Video,
                width: Some(1920),
                height: Some(1080),
                frame_rate: Some(30.0),
                frame_rate_fraction: Some("30/1".to_owned()),
                video_codec: Some("h264".to_owned()),
                audio_codec: None,
                has_audio: false,
                audio_tracks: Vec::new(),
                origin: None,
                color_space: Default::default(),
            },
        }
    }

    #[test]
    fn slots_come_back_in_timeline_order() {
        // c2 is listed first but starts later; the fill order is by time.
        let slots = slots_of(&template_document());
        assert_eq!(slots.len(), 2);
        assert_eq!(slots[0].media_id, "m1");
        assert_eq!(slots[0].seconds, 4.0);
        assert_eq!(slots[1].media_id, "m2");
    }

    #[test]
    fn saving_packs_a_bundle_and_it_round_trips() {
        let scratch = std::env::temp_dir().join("concat-template-save-test");
        let _ = std::fs::remove_dir_all(&scratch);
        let config = scratch.join("config");
        let project = scratch.join("project");
        std::fs::create_dir_all(&project).expect("scratch dirs");

        // A real file for the bundled music; the placeholder needs none.
        let music = project.join("music.mp3");
        std::fs::write(&music, b"not really an mp3").expect("writes");

        let mut document = template_document();
        {
            let media = document["media"].as_array_mut().expect("media");
            // m1 stays a placeholder; m2 becomes ordinary bundled media.
            media[1]["placeholder"] = Value::Bool(false);
            media[1]["path"] = Value::String(music.to_string_lossy().into_owned());
            media[1]["kind"] = Value::String("audio".to_owned());
        }

        let settings = DocumentSettings {
            canvas: [0, 0, 0, 255],
            name: "Beat Intro".to_owned(),
            width: 1920,
            height: 1080,
            rate_num: 30,
            rate_den: 1,
        };
        let info = save(
            &config,
            &document,
            &settings,
            &project.to_string_lossy(),
            "Beat Intro",
        )
        .expect("saves");
        assert_eq!(info.name, "Beat Intro");
        assert_eq!(info.slots.len(), 1, "only the placeholder is a slot");
        assert_eq!(info.slots[0].media_id, "m1");

        // The same name again is refused, not overwritten.
        assert!(
            save(
                &config,
                &document,
                &settings,
                &project.to_string_lossy(),
                "Beat Intro"
            )
            .is_err()
        );

        let bundle = PathBuf::from(&info.path);
        let packed: Value =
            serde_json::from_slice(&std::fs::read(bundle.join(MANIFEST)).expect("manifest"))
                .expect("parses");
        let media = packed["media"].as_array().expect("media");
        assert_eq!(media[0]["path"], "", "the placeholder's path is blanked");
        let bundled = media[1]["path"].as_str().expect("path");
        assert!(
            bundled.starts_with("assets/"),
            "bundled media went relative: {bundled}"
        );
        assert!(
            bundle.join(bundled).is_file(),
            "and the file really is in the bundle"
        );

        assert!(list(&config).iter().any(|item| item.name == "Beat Intro"), "the library sees it");

        // And it instantiates: the asset lands in the project, absolute.
        let location = scratch.join("projects");
        std::fs::create_dir_all(&location).expect("scratch dir");
        let made = instantiate(
            &info.path,
            &location.to_string_lossy(),
            "From bundle",
            vec![fill("m1", "/mine/clip.mp4", 6.0)],
        )
        .expect("instantiates");

        let opened = projects::read_document(&made.path)
            .expect("reads back")
            .expect("a document");
        let media = opened["media"].as_array().expect("media");
        let sound = media[1]["path"].as_str().expect("path");
        assert!(
            Path::new(sound).is_absolute() && Path::new(sound).is_file(),
            "the bundled asset was copied into the project and repointed: {sound}"
        );

        let _ = std::fs::remove_dir_all(&scratch);
    }

    #[test]
    fn instantiating_fills_through_the_engine() {
        let scratch = std::env::temp_dir().join("concat-template-test");
        let _ = std::fs::remove_dir_all(&scratch);
        let bundle = scratch.join("templates").join("Beat Intro");
        std::fs::create_dir_all(&bundle).expect("scratch dir");
        std::fs::write(
            bundle.join(MANIFEST),
            serde_json::to_vec(&template_document()).expect("encodes"),
        )
        .expect("writes");

        let projects_dir = scratch.join("projects");
        std::fs::create_dir_all(&projects_dir).expect("scratch dir");
        let location = projects_dir.to_string_lossy().into_owned();

        // Missing a slot is refused before any folder is written.
        let refused = instantiate(
            &bundle.to_string_lossy(),
            &location,
            "Missing",
            vec![fill("m1", "/mine/a.mp4", 9.0)],
        );
        assert!(refused.unwrap_err().contains("slot"));

        let project = instantiate(
            &bundle.to_string_lossy(),
            &location,
            "My edit",
            vec![
                fill("m1", "/mine/a.mp4", 9.0),
                fill("m2", "/mine/b.mp4", 9.0),
            ],
        )
        .expect("instantiates");
        assert_eq!((project.width, project.height), (1920, 1080));

        let document = projects::read_document(&project.path)
            .expect("reads back")
            .expect("a document");
        let media = document["media"].as_array().expect("media");
        assert!(media.iter().all(|item| {
            !item
                .get("placeholder")
                .and_then(Value::as_bool)
                .unwrap_or(false)
        }));
        assert_eq!(media[0]["path"], "/mine/a.mp4");
        // The slot kept the template's timing; the in-point reset (c1 had 1.0).
        let clips = document["clips"].as_array().expect("clips");
        let c1 = clips.iter().find(|clip| clip["id"] == "c1").expect("c1");
        assert_eq!(c1["start"], 0.0);
        assert_eq!(c1["duration"], 4.0);
        assert_eq!(c1["sourceStart"], 0.0);

        let _ = std::fs::remove_dir_all(&scratch);
    }

    #[test]
    fn builtin_smart_packs_are_listed() {
        let dir = builtin_smart_packs_dir();
        assert!(dir.is_dir(), "{}", dir.display());
        let packs = list_from(&dir);
        assert!(packs.len() >= 42, "marquee 智能包装 recipes, got {}", packs.len());
        assert!(packs.iter().any(|item| item.name.contains("口播")));
        assert!(packs.iter().find(|item| item.name == "口播配方").unwrap().slots.len() >= 3);
        assert!(
            packs.iter().all(|item| item.slots.len() >= 3),
            "every 智能包装 should be layered (video slots + music)"
        );
        let wide = packs.iter().find(|item| item.name == "三镜横屏包装").expect("wide pack");
        assert_eq!(wide.slots.len(), 4, "3 picture slots + music");
        assert_eq!(wide.width, 1920);
        let tall = packs.iter().find(|item| item.name == "三镜竖屏包装").expect("vertical pack");
        assert_eq!(tall.width, 1080);
        assert_eq!(tall.height, 1920);
    }

    /// Every built-in pack says what each slot wants: a label of its own,
    /// a hint, the frame's shape for a picture, and the music optional.
    #[test]
    fn builtin_packs_say_what_each_slot_wants() {
        for pack in list_from(&builtin_smart_packs_dir()) {
            let shape = Orientation::of(pack.width, pack.height);
            assert!(!pack.category.is_empty() && !pack.note.is_empty(), "{}", pack.name);
            assert!(pack.seconds > 1.0, "{} runs {}", pack.name, pack.seconds);
            for slot in &pack.slots {
                assert!(!slot.label.starts_with("画面"), "{}: {}", pack.name, slot.label);
                assert!(!slot.hint.is_empty(), "{}: {}", pack.name, slot.label);
                assert!(slot.seconds > 0.0, "{}: {}", pack.name, slot.label);
                if slot.kind == MediaKind::Audio {
                    assert!(slot.optional, "{}: the music is optional", pack.name);
                    assert_eq!(slot.orientation, None);
                } else {
                    assert!(!slot.optional, "{}: {}", pack.name, slot.label);
                    assert_eq!(slot.orientation, Some(shape), "{}", pack.name);
                }
            }
        }
        let talk = list_from(&builtin_smart_packs_dir())
            .into_iter()
            .find(|pack| pack.name == "口播配方")
            .expect("口播配方");
        let labels: Vec<&str> = talk.slots.iter().map(|slot| slot.label.as_str()).collect();
        assert_eq!(labels, ["人物口播", "补充画面", "配乐"]);
    }

    /// A template with no guide labels its slots by their names, and a
    /// guided one by its own words.
    #[test]
    fn a_slot_guide_labels_the_slots() {
        let plain = slots_of(&template_document());
        assert_eq!(plain[0].label, "A-roll");
        assert!(!plain[0].optional);
        assert_eq!(plain[0].orientation, Some(Orientation::Landscape));
        let mut guided = template_document();
        guided["marqueePack"] = json!({ "slots": [
            { "media": "m2", "label": "结尾空镜", "hint": "收尾", "optional": true }
        ]});
        let slots = slots_of(&guided);
        assert_eq!(slots[1].label, "结尾空镜");
        assert_eq!(slots[1].hint, "收尾");
        assert!(slots[1].optional);
        assert_eq!(slots[0].label, "A-roll");
    }

    /// An optional slot left empty is left out of the project, clips and
    /// all; a needed one still refuses, by name.
    #[test]
    fn an_optional_slot_can_be_left_empty() {
        let scratch = std::env::temp_dir().join("concat-template-optional-test");
        let _ = std::fs::remove_dir_all(&scratch);
        let bundle = scratch.join("templates").join("Guided");
        std::fs::create_dir_all(&bundle).expect("scratch dir");
        let mut document = template_document();
        document["marqueePack"] = json!({ "slots": [
            { "media": "m1", "label": "开场横拍" },
            { "media": "m2", "label": "结尾空镜", "optional": true }
        ]});
        std::fs::write(bundle.join(MANIFEST), serde_json::to_vec(&document).expect("encodes"))
            .expect("writes");
        let projects_dir = scratch.join("projects");
        std::fs::create_dir_all(&projects_dir).expect("scratch dir");
        let location = projects_dir.to_string_lossy().into_owned();

        let refused = instantiate(&bundle.to_string_lossy(), &location, "None", Vec::new())
            .expect_err("the opening is needed");
        assert!(refused.contains("开场横拍") && !refused.contains("结尾空镜"), "{refused}");

        let made = instantiate(
            &bundle.to_string_lossy(),
            &location,
            "Opening only",
            vec![fill("m1", "/mine/a.mp4", 9.0)],
        )
        .expect("instantiates without the optional slot");
        let document = projects::read_document(&made.path)
            .expect("reads back")
            .expect("a document");
        let media = document["media"].as_array().expect("media");
        assert_eq!(media.len(), 1);
        assert_eq!(media[0]["path"], "/mine/a.mp4");
        let clips = document["clips"].as_array().expect("clips");
        assert!(clips.iter().all(|clip| clip["mediaId"] != "m2"));
        let _ = std::fs::remove_dir_all(&scratch);
    }

    /// The posters on disk are the live render: each built-in pack's
    /// `poster.jpg` is its own edit at [`poster_time`] with the card still
    /// in its slots, drawn now, to within what JPEG and a GPU's rounding
    /// leave. Skips without FFmpeg or a GPU.
    #[test]
    fn builtin_posters_match_the_live_render() {
        let pool = concat_media::ReaderPool::new(64 * 1024 * 1024, 2);
        let mut checked = 0;
        for pack in list_from(&builtin_smart_packs_dir()) {
            assert!(pack.has_poster, "{} has no poster", pack.name);
            let Ok(frames) = preview_frames(&pack.path, &[poster_time(pack.seconds)], &pool)
            else {
                return; // no FFmpeg or GPU here
            };
            let live = &frames[0];
            let decode = |path: &Path| {
                let mut decoder =
                    concat_media::Decoder::open(path, &concat_media::DecodeOptions::default())
                        .expect("opens the picture");
                concat_media::FrameSource::next_frame(&mut decoder)
                    .expect("decodes")
                    .expect("a picture")
            };
            let mean = |a: &concat_core::frame::Frame, b: &concat_core::frame::Frame| {
                assert_eq!((a.width(), a.height()), (b.width(), b.height()), "{}", pack.name);
                let total: u64 = a
                    .pixels()
                    .iter()
                    .zip(b.pixels())
                    .map(|(a, b): (&u8, &u8)| u64::from(a.abs_diff(*b)))
                    .sum();
                total as f64 / a.pixels().len() as f64
            };
            // What JPEG and its decode cost on their own: the live frame
            // written the way the poster was and read back.
            let scratch = std::env::temp_dir().join(format!(
                "marquee-poster-check-{}.jpg",
                std::process::id()
            ));
            std::fs::write(&scratch, concat_media::jpeg(live, 92).expect("encodes"))
                .expect("writes");
            let floor = mean(live, &decode(&scratch));
            let _ = std::fs::remove_file(&scratch);
            let off = mean(live, &decode(&Path::new(&pack.path).join(POSTER)));
            eprintln!("{}: {off:.2} (JPEG alone {floor:.2})", pack.name);
            assert!(
                off <= floor + 0.5,
                "{}: the poster is {off:.2} off the live render, JPEG alone {floor:.2}",
                pack.name
            );
            checked += 1;
        }
        assert!(checked >= 42);
    }

    /// The offline tool: writes every built-in pack's poster from its live
    /// render. `cargo test -p concat-host --lib -- --ignored
    /// write_builtin_posters`.
    #[test]
    #[ignore]
    fn write_builtin_posters() {
        let pool = concat_media::ReaderPool::new(64 * 1024 * 1024, 2);
        for pack in list_from(&builtin_smart_packs_dir()) {
            let frames = preview_frames(&pack.path, &[poster_time(pack.seconds)], &pool)
                .expect("renders");
            let bytes = concat_media::jpeg(&frames[0], 92).expect("encodes");
            std::fs::write(Path::new(&pack.path).join(POSTER), bytes).expect("writes");
        }
    }

    #[test]
    fn builtin_layered_pack_parses() {
        let manifest = builtin_smart_packs_dir().join("marquee-pack-wide").join(MANIFEST);
        let document: Value = serde_json::from_slice(&std::fs::read(&manifest).expect("manifest"))
            .expect("json");
        assert!(
            concat_project::from_document(&document).is_some(),
            "三镜横屏包装 must open as a project"
        );
    }

    #[test]
    fn sticker_layers_are_not_full_frame() {
        for entry in std::fs::read_dir(builtin_smart_packs_dir()).unwrap() {
            let path = entry.unwrap().path().join(MANIFEST);
            if !path.is_file() {
                continue;
            }
            let document: Value = serde_json::from_slice(&std::fs::read(&path).unwrap()).unwrap();
            let Some(clips) = document.get("clips").and_then(|c| c.as_array()) else {
                continue;
            };
            for clip in clips {
                if clip.get("id").and_then(|v| v.as_str()) == Some("c-sticker") {
                    let scale = clip.get("scale").and_then(|v| v.as_f64()).unwrap_or(1.0);
                    assert!(
                        scale <= 0.35,
                        "{} sticker scale {scale} should be JY-sized",
                        path.display()
                    );
                }
                if clip.get("id").and_then(|v| v.as_str()) == Some("c-title") {
                    let size = clip
                        .pointer("/text/fontSize")
                        .and_then(|v| v.as_f64())
                        .unwrap_or(0.1);
                    assert!(
                        size <= 0.07,
                        "{} title fontSize {size} should not dominate the frame",
                        path.display()
                    );
                    let color = clip
                        .pointer("/text/color")
                        .and_then(|v| v.as_str())
                        .unwrap_or("");
                    assert!(
                        !is_cyan_hex(color),
                        "{} title color {color} is too cyan",
                        path.display()
                    );
                }
                if clip.get("id").and_then(|v| v.as_str()) == Some("c-sticker") {
                    let fx = clip
                        .pointer("/videoEffects/0/id")
                        .and_then(|v| v.as_str())
                        .unwrap_or("");
                    assert_ne!(fx, "marquee.ch01", "{} still uses the cyan chat slab", path.display());
                    let scale = clip.get("scale").and_then(|v| v.as_f64()).unwrap_or(1.0);
                    assert!(
                        (0.16..=0.24).contains(&scale),
                        "{} sticker scale {scale} should match JY default (~0.20)",
                        path.display()
                    );
                }
            }
        }
    }

    fn is_cyan_hex(color: &str) -> bool {
        let hex = color.trim().trim_start_matches('#');
        if hex.len() < 6 {
            return false;
        }
        let parse = |i| u8::from_str_radix(&hex[i..i + 2], 16).ok();
        match (parse(0), parse(2), parse(4)) {
            (Some(r), Some(g), Some(b)) => b > r.saturating_add(20) && g > r.saturating_add(10),
            _ => false,
        }
    }

    #[test]
    fn builtin_talk_pack_parses() {
        let manifest = builtin_smart_packs_dir().join("marquee-talk").join(MANIFEST);
        let document: Value = serde_json::from_slice(&std::fs::read(&manifest).expect("manifest"))
            .expect("json");
        assert!(
            concat_project::from_document(&document).is_some(),
            "口播配方 must open as a project so the gallery can instantiate it"
        );
    }
}
