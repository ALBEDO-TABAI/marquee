// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jareer Abdullah and Concat contributors

//! Hover previews for the library shelves.
//!
//! One background thread paints the tile under the pointer. A text look and
//! a shape go through the same painters an inserted clip uses. An effect,
//! filter, transition, sticker or text animation goes through the same
//! compositor as its shelf still, on a device of that thread's own so the
//! monitor's queue is left alone. Nothing here writes the project, the
//! undo stack, the selection or the playhead.
//!
//! A newer hover, or the pointer leaving, bumps a generation. A frame that
//! belongs to an older one is dropped, including one that was already in
//! flight. The thread keeps a single job waiting, so a fast scrub across
//! the shelf does not queue a render per card. Finished sequences are kept
//! in a bounded cache on the UI side.

use std::collections::VecDeque;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Condvar, Mutex};
use std::thread::JoinHandle;
use std::time::Duration;

use concat_host::titles::CardPixels;
use concat_project::model::TextStyle;

/// How many finished sequences the shelf remembers. Each is a handful of
/// small frames; past this the oldest is dropped.
const CACHE: usize = 24;

/// The square a text or shape hover is painted at.
const TEXT_SIDE: u32 = 144;

/// Whether the pointer asked not to be shown motion. `CONCAT_REDUCE_MOTION=1`
/// forces it, which is how the tests and a headless run pin the state. A
/// GNOME desktop that has turned animations off counts too; anything else,
/// including a setting that does not answer quickly, is motion allowed.
pub fn reduce_motion() -> bool {
    if std::env::var("CONCAT_REDUCE_MOTION").ok().as_deref() == Some("1") {
        return true;
    }
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let off = std::process::Command::new("gsettings")
            .args(["get", "org.gnome.desktop.interface", "enable-animations"])
            .output()
            .ok()
            .and_then(|out| String::from_utf8(out.stdout).ok())
            .is_some_and(|text| text.to_ascii_lowercase().contains("false"));
        let _ = tx.send(off);
    });
    rx.recv_timeout(Duration::from_millis(250)).unwrap_or(false)
}

/// Which shelf the pointer is on.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Kind {
    /// A text preset: flower text, a template or a language look.
    Text,
    /// A shape from the stickers page.
    Shape,
    /// An effect, filter, transition, sticker or text animation package.
    Package,
}

/// What the thread should paint for one hover.
struct HoverJob {
    generation: u64,
    kind: Kind,
    id: String,
    style: Option<TextStyle>,
    sample: String,
}

struct WarmItem {
    id: String,
    style: TextStyle,
    sample: String,
}

enum Pending {
    Hover(HoverJob),
    Warm(WarmItem),
}

struct Slot {
    /// The hover waiting, if the pointer has moved, and the looks still to
    /// be painted for the shelf. A hover is always taken first.
    queue: Mutex<Queue>,
    wake: Condvar,
}

struct Queue {
    hover: Option<HoverJob>,
    warm: VecDeque<WarmItem>,
}

/// One remembered sequence.
pub struct Cached {
    /// `text:<id>`, `shape:<id>` or `package:<id>`.
    pub key: String,
    /// The frames, in play order.
    pub frames: Vec<CardPixels>,
    /// Whether the shelf cycles them. A text look plays once, from the
    /// plain words to the treatment, and then holds.
    pub looped: bool,
}

/// The generation and the cache. Touched on the UI thread only; the worker
/// shares the generation counter and the job slot.
pub struct Gallery {
    generation: Arc<AtomicU64>,
    /// The key the pointer is on, when it is on a tile.
    current: Option<String>,
    cache: VecDeque<Cached>,
    slot: Arc<Slot>,
    _thread: Option<JoinHandle<()>>,
}

impl Gallery {
    /// The worker, idle until a hover or a warm-up is asked for.
    pub fn new() -> Gallery {
        let generation = Arc::new(AtomicU64::new(0));
        let slot = Arc::new(Slot {
            queue: Mutex::new(Queue {
                hover: None,
                warm: VecDeque::new(),
            }),
            wake: Condvar::new(),
        });
        let thread = spawn_worker(Arc::clone(&generation), Arc::clone(&slot));
        Gallery {
            generation,
            current: None,
            cache: VecDeque::new(),
            slot,
            _thread: Some(thread),
        }
    }

    /// The pointer entered `id`. Returns the generation the result must
    /// carry, and a cached sequence when one is already painted.
    pub fn hover(
        &mut self,
        kind: Kind,
        id: &str,
        style: Option<TextStyle>,
        sample: &str,
    ) -> (u64, Option<Cached>) {
        let key = key_of(kind, id);
        let generation = self.generation.fetch_add(1, Ordering::AcqRel) + 1;
        self.current = Some(key.clone());
        if let Some(hit) = self.take_cached(&key) {
            // Put it back at the new end, so a hit counts as recent.
            self.cache.push_back(Cached {
                key: hit.key.clone(),
                frames: hit.frames.clone(),
                looped: hit.looped,
            });
            return (generation, Some(hit));
        }
        let job = HoverJob {
            generation,
            kind,
            id: id.to_owned(),
            style,
            sample: sample.to_owned(),
        };
        {
            let mut queue = self.slot.queue.lock().unwrap_or_else(|e| e.into_inner());
            queue.hover = Some(job);
        }
        self.slot.wake.notify_one();
        (generation, None)
    }

    /// The pointer left the tile. Any frame still in flight is now stale.
    pub fn leave(&mut self) {
        self.generation.fetch_add(1, Ordering::AcqRel);
        self.current = None;
        let mut queue = self.slot.queue.lock().unwrap_or_else(|e| e.into_inner());
        queue.hover = None;
    }

    /// Remember `frames` when `generation` is still the hover on `id`.
    pub fn store(
        &mut self,
        generation: u64,
        id: &str,
        frames: Vec<CardPixels>,
        looped: bool,
    ) -> bool {
        if !self.accept(generation, id) {
            return false;
        }
        if let Some(key) = self.current.clone() {
            self.remember(Cached {
                key,
                frames,
                looped,
            });
        }
        true
    }

    /// Whether a result stamped `generation` for `id` is still the tile the
    /// pointer is on.
    pub fn accept(&self, generation: u64, id: &str) -> bool {
        self.generation.load(Ordering::Acquire) == generation
            && self
                .current
                .as_deref()
                .is_some_and(|key| key.ends_with(&format!(":{id}")))
    }

    /// Remember a sequence the thread just painted. Drops the oldest past
    /// [`CACHE`].
    pub fn remember(&mut self, cached: Cached) {
        self.cache.retain(|held| held.key != cached.key);
        self.cache.push_back(cached);
        while self.cache.len() > CACHE {
            self.cache.pop_front();
        }
    }

    /// Paint every text look's still, a few at a time, behind the shelf.
    /// A hover is taken ahead of whatever is left.
    pub fn warm(&mut self, items: Vec<(String, TextStyle, String)>) {
        let mut queue = self.slot.queue.lock().unwrap_or_else(|e| e.into_inner());
        for (id, style, sample) in items {
            queue.warm.push_back(WarmItem { id, style, sample });
        }
        drop(queue);
        self.slot.wake.notify_one();
    }

    fn take_cached(&mut self, key: &str) -> Option<Cached> {
        let index = self.cache.iter().position(|held| held.key == key)?;
        self.cache.remove(index)
    }
}

fn key_of(kind: Kind, id: &str) -> String {
    let prefix = match kind {
        Kind::Text => "text",
        Kind::Shape => "shape",
        Kind::Package => "package",
    };
    format!("{prefix}:{id}")
}

fn spawn_worker(generation: Arc<AtomicU64>, slot: Arc<Slot>) -> JoinHandle<()> {
    std::thread::Builder::new()
        .name("marquee gallery".to_owned())
        .spawn(move || worker(generation, slot))
        .expect("the gallery thread starts")
}

fn worker(generation: Arc<AtomicU64>, slot: Arc<Slot>) {
    let mut painter: Option<concat_host::cards::Painter> = None;
    loop {
        let next = {
            let mut queue = slot.queue.lock().unwrap_or_else(|e| e.into_inner());
            while queue.hover.is_none() && queue.warm.is_empty() {
                queue = slot.wake.wait(queue).unwrap_or_else(|e| e.into_inner());
            }
            if let Some(hover) = queue.hover.take() {
                Pending::Hover(hover)
            } else {
                Pending::Warm(queue.warm.pop_front().expect("a warm item"))
            }
        };
        match next {
            Pending::Hover(job) => {
                if generation.load(Ordering::Acquire) != job.generation {
                    continue;
                }
                let stop = {
                    let generation = Arc::clone(&generation);
                    let expected = job.generation;
                    move || generation.load(Ordering::Acquire) != expected
                };
                match render_hover(&job, &stop, &mut painter) {
                    Ok((frames, looped)) => {
                        if stop() {
                            continue;
                        }
                        let id = job.id.clone();
                        let generation = job.generation;
                        crate::host::on_ui_quiet(move |studio, app, _| {
                            studio.gallery_arrived(app, generation, &id, frames, looped, false);
                        });
                    }
                    Err(error) => {
                        if error == "cancelled"
                            || generation.load(Ordering::Acquire) != job.generation
                        {
                            continue;
                        }
                        log::debug!("gallery preview {}: {error}", job.id);
                        let id = job.id.clone();
                        let generation = job.generation;
                        crate::host::on_ui_quiet(move |studio, app, _| {
                            studio.gallery_arrived(app, generation, &id, Vec::new(), false, true);
                        });
                    }
                }
            }
            Pending::Warm(item) => {
                let mut batch = vec![item];
                {
                    let mut queue = slot.queue.lock().unwrap_or_else(|e| e.into_inner());
                    if queue.hover.is_none() {
                        while batch.len() < 4 {
                            let Some(more) = queue.warm.pop_front() else {
                                break;
                            };
                            batch.push(more);
                        }
                    }
                }
                let mut painted = Vec::new();
                for item in batch {
                    match concat_host::titles::preset_card(
                        &item.style,
                        &item.sample,
                        TEXT_SIDE,
                        false,
                    ) {
                        Ok(card) => painted.push((item.id, card)),
                        Err(error) => log::debug!("preset card {}: {error}", item.id),
                    }
                }
                if !painted.is_empty() {
                    crate::host::on_ui_quiet(move |studio, _, models| {
                        for (id, card) in painted {
                            studio.preset_art_arrived(&id, card, models);
                        }
                    });
                }
            }
        }
    }
}

fn render_hover(
    job: &HoverJob,
    stop: &dyn Fn() -> bool,
    painter: &mut Option<concat_host::cards::Painter>,
) -> Result<(Vec<CardPixels>, bool), String> {
    if stop() {
        return Err("cancelled".to_owned());
    }
    match job.kind {
        Kind::Text => {
            let style = job.style.as_ref().ok_or("the look has no style")?;
            let before = concat_host::titles::preset_card(style, &job.sample, TEXT_SIDE, true)?;
            if stop() {
                return Err("cancelled".to_owned());
            }
            let after = concat_host::titles::preset_card(style, &job.sample, TEXT_SIDE, false)?;
            Ok((vec![before, after], false))
        }
        Kind::Shape => {
            let card = concat_host::titles::shape_card(&job.id, TEXT_SIDE)?;
            Ok((vec![card], false))
        }
        Kind::Package => {
            let painter = painter_of(painter)?;
            let frames = painter.preview(concat_effects::Catalogue::builtin(), &job.id, stop)?;
            let frames = frames
                .into_iter()
                .map(|frame| CardPixels {
                    width: frame.width(),
                    height: frame.height(),
                    rgba: frame.pixels().to_vec(),
                })
                .collect();
            Ok((frames, true))
        }
    }
}

fn painter_of(
    slot: &mut Option<concat_host::cards::Painter>,
) -> Result<&mut concat_host::cards::Painter, String> {
    if slot.is_none() {
        let gpu = concat_render::WgpuCompositor::new()
            .or_else(concat_render::WgpuCompositor::software)
            .ok_or("no compositor for a hover preview")?;
        let path = std::env::temp_dir().join("marquee-card-still.jpg");
        if !path.is_file() {
            std::fs::write(&path, concat_host::cards::STILL).map_err(|error| error.to_string())?;
        }
        *slot = Some(
            concat_host::cards::Painter::new(gpu, &path, 160, 160)
                .map_err(|error| error.to_string())?,
        );
    }
    Ok(slot.as_mut().expect("just set"))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A stand-in for the generation rules, without a thread or a GPU:
    /// leave and a newer hover reject the frame that was in flight, and
    /// the cache forgets the oldest past its cap.
    struct Gate {
        generation: u64,
        current: Option<String>,
        cache: VecDeque<String>,
    }

    impl Gate {
        fn hover(&mut self, id: &str) -> u64 {
            self.generation += 1;
            self.current = Some(id.to_owned());
            self.generation
        }

        fn leave(&mut self) {
            self.generation += 1;
            self.current = None;
        }

        fn accept(&self, generation: u64, id: &str) -> bool {
            self.generation == generation && self.current.as_deref() == Some(id)
        }

        fn remember(&mut self, id: &str) {
            self.cache.retain(|held| held != id);
            self.cache.push_back(id.to_owned());
            while self.cache.len() > CACHE {
                self.cache.pop_front();
            }
        }
    }

    #[test]
    fn a_leave_or_a_newer_hover_drops_the_frame_in_flight() {
        let mut gate = Gate {
            generation: 0,
            current: None,
            cache: VecDeque::new(),
        };
        let first = gate.hover("outline");
        assert!(gate.accept(first, "outline"));
        gate.leave();
        assert!(!gate.accept(first, "outline"), "leaving cancels");
        let second = gate.hover("neon");
        let third = gate.hover("drop");
        assert!(!gate.accept(second, "neon"), "a newer hover wins");
        assert!(gate.accept(third, "drop"));
        assert!(!gate.accept(third, "neon"));
    }

    #[test]
    fn the_cache_keeps_a_bounded_number_of_sequences() {
        let mut gate = Gate {
            generation: 0,
            current: None,
            cache: VecDeque::new(),
        };
        for index in 0..(CACHE + 5) {
            gate.remember(&format!("id-{index}"));
        }
        assert_eq!(gate.cache.len(), CACHE);
        assert!(!gate.cache.iter().any(|id| id == "id-0"));
        assert!(gate.cache.back().is_some_and(|id| id == "id-28"));
        gate.remember("id-10");
        assert_eq!(gate.cache.len(), CACHE);
        assert_eq!(gate.cache.back().map(String::as_str), Some("id-10"));
    }
}
