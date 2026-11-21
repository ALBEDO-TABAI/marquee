// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Jareer Abdullah and Concat contributors
//! The bin: the project's media, its art, posters and strips.

use super::*;

impl Studio {
    // ── the bin ──

    /// Gives every media item the row Slint knows it by; see
    /// `MediaBin::assign_rows`.
    pub(super) fn assign_media_rows(&mut self) {
        let mut bin = std::mem::take(&mut self.media);
        bin.assign_rows(self.project());
        self.media = bin;
    }

    /// Decodes art for every media item that has none yet: its pictures
    /// and the waveform of its default audio stream - and, for every clip
    /// that plays another of its media's streams, that stream's waveform
    /// too, so a lane shows the sound it will make.
    pub(crate) fn request_media_art(&mut self) {
        let Some(session) = self.session.as_ref() else {
            return;
        };
        let project_path = session.path().to_owned();
        // With proxies on in Settings, a file larger than HD gets a proxy
        // for playback and the filmstrips, written once on the scheduler's
        // proxy lane; see concat_host::proxy. Asked once per file per
        // project. Off, the default, nothing is written.
        type Unproxied = (
            String,
            String,
            u32,
            u32,
            Option<concat_media::ColorRange>,
            bool,
        );
        let unproxied: Vec<Unproxied> = self
            .project()
            .media
            .iter()
            .filter(|_| self.prefs.proxies)
            .filter(|item| item.kind == model::MediaKind::Video && !item.placeholder)
            .filter(|item| !self.proxied.contains(&item.id))
            .filter_map(|item| {
                let (width, height) = (item.width?, item.height?);
                Some((
                    item.id.clone(),
                    item.path.clone(),
                    width,
                    height,
                    item.color_range.map(concat_export::engine_range),
                    item.color_space.is_hdr(),
                ))
            })
            .collect();
        for (id, path, width, height, range, hdr) in unproxied {
            concat_host::proxy::ensure(
                std::path::Path::new(&project_path),
                &path,
                width,
                height,
                range,
                hdr,
            );
            self.proxied.insert(id);
        }
        /// A media item whose own art is missing, or another of its audio
        /// streams whose waveform a clip plays.
        struct Want {
            id: String,
            path: String,
            kind: model::MediaKind,
            has_audio: bool,
            duration: Option<f64>,
            /// The stream whose waveform alone is wanted, or `None` for
            /// the item's own art: its picture, filmstrip and waveform.
            stream: Option<u32>,
            /// The levels the file is read as, so the filmstrip reads the
            /// proxy written for that reading.
            range: Option<concat_media::ColorRange>,
        }
        let project = self.project();
        let mut wanted: Vec<Want> = project
            .media
            .iter()
            .filter(|item| !item.placeholder && !item.path.is_empty())
            .filter(|item| self.missing_art(&item.id, item.kind, item.has_audio).any())
            .map(|item| Want {
                id: item.id.clone(),
                path: item.path.clone(),
                kind: item.kind,
                has_audio: item.has_audio,
                duration: item.duration,
                stream: None,
                range: item.color_range.map(concat_export::engine_range),
            })
            .collect();
        // The other streams clips have chosen, once each.
        let mut asked: HashSet<String> = HashSet::new();
        for clip in project
            .timelines
            .iter()
            .flat_map(|timeline| timeline.clips.iter())
        {
            let Some(stream) = clip.audio_stream else {
                continue;
            };
            let Some(item) = project.media_by_id(&clip.media_id) else {
                continue;
            };
            if item.placeholder
                || item.path.is_empty()
                || !(item.kind == model::MediaKind::Audio || item.has_audio)
            {
                continue;
            }
            let key = art_key(&item.id, Some(stream));
            if self.peaks.contains_key(&key)
                || self.art_pending.contains(&key)
                || self.art_failed.contains(&key)
                || !asked.insert(key)
            {
                continue;
            }
            wanted.push(Want {
                id: item.id.clone(),
                path: item.path.clone(),
                kind: item.kind,
                has_audio: item.has_audio,
                duration: item.duration,
                stream: Some(stream),
                range: item.color_range.map(concat_export::engine_range),
            });
        }
        // Each piece of art is a job of its own, on the scheduler's lane
        // for it (see host.rs): the cards' pictures first and on every
        // worker, then the waveforms, then the filmstrips, a few at a
        // time. A card shows its picture the moment its one frame is
        // decoded, never after a filmstrip - its own, or those of every
        // file imported before it.
        for want in wanted {
            let Want {
                id,
                path,
                kind,
                has_audio,
                duration,
                stream,
                range,
            } = want;
            let project = project_path.clone();

            if let Some(stream) = stream {
                self.art_pending.insert(art_key(&id, Some(stream)));
                spawn_wave(
                    move || media_peaks(id, path, project, Some(stream)),
                    Self::peaks_landed,
                );
                continue;
            }

            // Restore pictures from the project's JPEG artwork cache before
            // starting a decoder. Peaks already have their own disk cache in
            // concat-media; thumbnails and filmstrips are what used to be
            // recreated on every project open.
            let mut missing = self.missing_art(&id, kind, has_audio);
            if missing.poster || missing.strip {
                let cached = cached_media_art(&project_path, &id, &path, kind);
                if let Some(image) = cached.thumbnail {
                    self.media.thumbs.insert(id.clone(), image);
                }
                if let Some(strip) = cached.strip {
                    self.strips.insert(id.clone(), strip.into());
                }
                missing = self.missing_art(&id, kind, has_audio);
            }

            if missing.poster {
                self.art_pending.insert(poster_key(&id));
                let (id, path, project) = (id.clone(), path.clone(), project.clone());
                spawn_poster(
                    move || media_poster(id, path, kind, duration, project),
                    |studio, _, _, poster: MediaPoster| {
                        let key = poster_key(&poster.id);
                        studio.art_pending.remove(&key);
                        match poster.thumbnail {
                            Some(frame) => {
                                studio
                                    .media
                                    .thumbs
                                    .insert(poster.id.clone(), image_of(&frame));
                            }
                            None => {
                                studio.art_failed.insert(key);
                            }
                        }
                        if let Some((frame, frames)) = poster.strip {
                            studio.strips.insert(poster.id, Strip::of(&frame, frames));
                        }
                    },
                );
            }
            if missing.peaks {
                self.art_pending.insert(art_key(&id, None));
                let (id, path, project) = (id.clone(), path.clone(), project.clone());
                spawn_wave(
                    move || media_peaks(id, path, project, None),
                    Self::peaks_landed,
                );
            }
            if missing.strip {
                self.art_pending.insert(strip_key(&id));
                spawn_art(
                    move || media_strip(id, path, project, range),
                    |studio, _, _, art: MediaArt| {
                        let key = strip_key(&art.id);
                        studio.art_pending.remove(&key);
                        match art.strip {
                            Some((frame, frames)) => {
                                studio.strips.insert(art.id, Strip::of(&frame, frames));
                            }
                            None => {
                                studio.art_failed.insert(key);
                            }
                        }
                    },
                );
            }
        }
        self.request_window_art();
    }

    /// What of media item `id`'s own art is neither held, nor being made,
    /// nor known not to come: its card's picture (a still's is its
    /// filmstrip too), its filmstrip, its first stream's waveform.
    pub(super) fn missing_art(
        &self,
        id: &str,
        kind: model::MediaKind,
        has_audio: bool,
    ) -> MissingArt {
        let open = |key: &str| !self.art_pending.contains(key) && !self.art_failed.contains(key);
        MissingArt {
            poster: kind != model::MediaKind::Audio
                && (!self.media.thumbs.contains_key(id)
                    || (kind == model::MediaKind::Image && !self.strips.contains_key(id)))
                && open(&poster_key(id)),
            strip: kind == model::MediaKind::Video
                && !self.strips.contains_key(id)
                && open(&strip_key(id)),
            peaks: (kind == model::MediaKind::Audio || has_audio)
                && !self.peaks.contains_key(id)
                && open(&art_key(id, None)),
        }
    }

    /// A waveform decoded on a worker, in its place: the drawn envelopes
    /// made from the one before it, if any, go with it.
    fn peaks_landed(&mut self, _: &App, _: &Models, art: MediaArt) {
        let key = art_key(&art.id, art.stream);
        self.art_pending.remove(&key);
        match art.peaks {
            Some(peaks) => {
                let prefix = format!("{key}|");
                self.peaks.insert(key, peaks);
                self.waves
                    .borrow_mut()
                    .retain(|key, _| !key.starts_with(&prefix));
            }
            None => {
                self.art_failed.insert(key);
            }
        }
    }

    /// Decodes a cell strip for every picture clip on the current timeline
    /// whose cut is too short a piece of its footage for the file's own
    /// strip - see `host::strip_window` - and lets go of the cells nothing
    /// shows once there are more than `WINDOWS_KEPT` of them.
    pub(super) fn request_window_art(&mut self) {
        let Some(session) = self.session.as_ref() else {
            return;
        };
        let project_path = session.path().to_owned();
        struct Want {
            key: String,
            id: String,
            path: String,
            level: u32,
            cell: u32,
            duration: f64,
        }
        let mut shown: HashSet<String> = HashSet::new();
        let mut wanted: Vec<Want> = Vec::new();
        for clip in &self.timeline().clips {
            if clip.kind != model::ClipKind::Video {
                continue;
            }
            let Some(item) = self.project().media_by_id(&clip.media_id) else {
                continue;
            };
            if item.placeholder || item.path.is_empty() {
                continue;
            }
            let Some((start, span, duration)) = self.cut_of(clip) else {
                continue;
            };
            let Some((level, cell)) = strip_window(start, span, duration) else {
                continue;
            };
            let key = window_key(&clip.media_id, level, cell);
            if !shown.insert(key.clone())
                || self.windows.contains_key(&key)
                || self.window_pending.contains(&key)
            {
                continue;
            }
            wanted.push(Want {
                key,
                id: item.id.clone(),
                path: item.path.clone(),
                level,
                cell,
                duration,
            });
        }
        if self.windows.len() > WINDOWS_KEPT {
            self.windows.retain(|key, _| shown.contains(key));
        }
        for want in wanted {
            let Want {
                key,
                id,
                path,
                level,
                cell,
                duration,
            } = want;
            if let Some(strip) = cached_window_art(&project_path, &id, &path, level, cell) {
                self.windows.insert(key, strip.into());
                continue;
            }
            self.window_pending.insert(key);
            let project = project_path.clone();
            spawn_strip(
                move || window_art(id, path, project, level, cell, duration),
                |studio, _, _, art: WindowArt| {
                    let key = window_key(&art.id, art.level, art.cell);
                    studio.window_pending.remove(&key);
                    if let Some((frame, frames)) = art.strip {
                        studio.windows.insert(key, Strip::of(&frame, frames));
                    }
                },
            );
        }
    }

    /// A picture clip's cut as fractions of its footage - where it begins
    /// and how much it covers - with the footage's length in seconds.
    /// `None` for a still or footage of unknown length: one frame, all of it.
    fn cut_of(&self, clip: &Clip) -> Option<(f64, f64, f64)> {
        let seconds = self
            .project()
            .media
            .iter()
            .find(|item| item.id == clip.media_id)
            .and_then(|item| item.duration)
            .filter(|seconds| *seconds > 0.0)?;
        Some((
            (clip.source_start / seconds).clamp(0.0, 1.0),
            (clip.duration * clip.speed / seconds).clamp(0.0, 1.0),
            seconds,
        ))
    }

    /// The clip's filmstrip, with the window of the strip its cut covers:
    /// where in the footage it starts and how much of the footage it spans,
    /// both as fractions, so the lane can pick the frame under each tile
    /// without knowing about speed or source time.
    pub(super) fn strip_of(&self, clip: &Clip) -> StripData {
        if !matches!(clip.kind, model::ClipKind::Video | model::ClipKind::Image) {
            return StripData::default();
        }
        let Some(mut strip) = self.strips.get(&clip.media_id) else {
            return StripData::default();
        };
        let (mut start, mut span) = (0.0, 1.0);
        if let Some((cut_start, cut_span, duration)) = self.cut_of(clip) {
            start = cut_start;
            span = cut_span;
            // The cell strip, once it is here: the cut re-expressed as a
            // window of that cell rather than of the whole file. Until it
            // arrives the file's strip stands in, and the tiles repeat.
            if let Some((level, cell)) = strip_window(start, span, duration)
                && let Some(window) = self.windows.get(&window_key(&clip.media_id, level, cell))
            {
                let (cell_start, cell_span) = (window_start(level, cell), window_span(level));
                start = ((start - cell_start) / cell_span).clamp(0.0, 1.0);
                span = (span / cell_span).clamp(0.0, 1.0);
                strip = window;
            }
        }
        StripData {
            image: strip.image.clone(),
            frames: strip.frames,
            frame_width: strip.frame_width,
            height: strip.height,
            start: start as f32,
            span: span as f32,
        }
    }

    /// The memoised envelope for one clip, quantised to a thirtieth of a
    /// second so a trim revisits a handful of entries rather than minting
    /// one per pointer event, and to a step of columns so a zoom rebuilds
    /// it at each step of that and not at every pixel. A sound clip's
    /// whole body, a picture clip's band under its frames; a picture that
    /// is muted, or whose file has no sound, shows the empty band.
    ///
    /// At unity: the clip's volume scales the drawing in the lane, so a
    /// volume drag never comes here - see `format::wave_path`.
    ///
    /// Only the window of the clip that is on screen, and a screen either
    /// side of it, is built: what comes back is the path and where it
    /// sits on the clip, as fractions of the clip's length. A clip zoomed
    /// in far enough to be wider than the screen many times over would
    /// otherwise spread its bars across all of that width - a bar the
    /// width of a finger - or want tens of thousands of them. This way a
    /// bar is one pitch on screen at every zoom, and the count is bounded
    /// by the screen, not the clip. The window is quantised to strides
    /// of sixty-four bars, so a scroll rebuilds at each stride and not at
    /// every pixel, and the cache holds a few hundred windows before it
    /// is emptied.
    pub(super) fn wave(&self, clip: &Clip) -> (SharedString, f32, f32) {
        if clip.muted == Some(true) {
            return Default::default();
        }
        // The stream this clip plays; its peaks come when they are decoded,
        // and until then the lane is bare rather than showing another
        // track's shape.
        let art = art_key(&clip.media_id, clip.audio_stream);
        let Some(peaks) = self.peaks.get(&art) else {
            return Default::default();
        };
        let step = |seconds: f32| (seconds * WAVE_STEPS).round() / WAVE_STEPS;
        let (source_start, duration) = (step(clip.source_start as f32), step(clip.duration as f32));
        if duration <= 0.0 {
            return Default::default();
        }
        let seconds_per_pixel = self.lanes.seconds_per_pixel;
        let stride = (WAVE_PITCH * seconds_per_pixel * 64.0).max(1.0 / WAVE_STEPS);
        let (from, to) = match self.lanes.published_span() {
            Some((left, right)) => {
                let from = (left - clip.start as f32).max(0.0);
                let to = (right - clip.start as f32).min(duration);
                if to > from {
                    (
                        (from / stride).floor() * stride,
                        ((to / stride).ceil() * stride).min(duration),
                    )
                } else {
                    (0.0, duration)
                }
            }
            None => (0.0, duration),
        };
        let window = to - from;
        let columns = wave_columns(window, seconds_per_pixel);
        let placed = (from / duration, window / duration);
        let key = format!("{art}|{source_start:.3}|{from:.3}|{window:.3}|{columns}");
        if let Some(cached) = self.waves.borrow().get(&key) {
            return (cached.clone(), placed.0, placed.1);
        }
        let built = SharedString::from(wave_path(
            peaks,
            source_start + from,
            window,
            columns,
            WAVE_BAR,
        ));
        let mut waves = self.waves.borrow_mut();
        if waves.len() >= 512 {
            waves.clear();
        }
        waves.insert(key, built.clone());
        (built, placed.0, placed.1)
    }
}

/// Where a sound's beats are kept: beside the file, `song.beats.json`, a
/// JSON list of seconds. The Audio page writes it when it copies a song
/// of the library into a project.
pub fn beats_file(media: &std::path::Path) -> std::path::PathBuf {
    media.with_extension("beats.json")
}

/// A clip's beats in timeline seconds, from the media's in source seconds:
/// those inside what the clip plays, at its speed.
pub fn beat_times(beats: &[f64], source_start: f64, speed: f64, duration: f64) -> Vec<f32> {
    if speed <= 0.0 || duration <= 0.0 {
        return Vec::new();
    }
    beats
        .iter()
        .map(|beat| (beat - source_start) / speed)
        .filter(|at| *at >= 0.0 && *at <= duration)
        .map(|at| at as f32)
        .collect()
}

/// The beats as a path of one-pixel bars in a 1x1 box, the clip's whole
/// length across: bars closer than `gap` seconds to the one before are
/// left out, so a zoomed-out clip is not a solid colour.
pub fn beats_commands(times: &[f32], duration: f32, seconds_per_pixel: f32) -> String {
    use std::fmt::Write;
    if duration <= 0.0 {
        return String::new();
    }
    let gap = seconds_per_pixel * 4.0;
    let width = seconds_per_pixel / duration;
    let mut out = String::new();
    let mut last = f32::NEG_INFINITY;
    for &at in times {
        if at - last < gap {
            continue;
        }
        last = at;
        let x = at / duration;
        let _ = write!(out, "M{x:.6} 0 H{:.6} V1 H{x:.6} Z ", x + width);
    }
    out
}

impl Studio {
    /// A media's beats, in its own seconds: read once from the file beside
    /// it, and none when there is not one.
    pub fn media_beats(&self, media_id: &str) -> Arc<Vec<f64>> {
        let Some(item) = self.project().media.iter().find(|item| item.id == media_id) else {
            return Arc::default();
        };
        if let Some(held) = self.beat_cache.borrow().get(&item.path) {
            return held.clone();
        }
        let beats: Vec<f64> = std::fs::read(beats_file(std::path::Path::new(&item.path)))
            .ok()
            .and_then(|bytes| serde_json::from_slice(&bytes).ok())
            .unwrap_or_default();
        let beats = Arc::new(beats);
        self.beat_cache
            .borrow_mut()
            .insert(item.path.clone(), beats.clone());
        beats
    }

    /// Writes a sound's beats beside its copy in the project, unless they
    /// are there, so the lane can draw them and a drag snap to them.
    pub fn keep_beats(&self, media: &std::path::Path, beats: &[f64]) {
        let side = beats_file(media);
        if beats.is_empty() || side.exists() {
            return;
        }
        if let Ok(text) = serde_json::to_vec(beats) {
            let partial = side.with_extension("partial");
            if std::fs::write(&partial, text).is_ok() {
                let _ = std::fs::rename(&partial, &side);
            }
        }
        self.forget_beats(&media.to_string_lossy());
    }

    /// Forgets what was read of a media's beats: its file was written.
    pub fn forget_beats(&self, path: &str) {
        self.beat_cache.borrow_mut().remove(path);
    }

    /// A clip's beats on the timeline, in seconds.
    pub fn clip_beats(&self, clip: &Clip) -> Vec<f32> {
        if clip.media_id.is_empty() {
            return Vec::new();
        }
        let beats = self.media_beats(&clip.media_id);
        if beats.is_empty() {
            return Vec::new();
        }
        beat_times(&beats, clip.source_start, clip.speed, clip.duration)
            .into_iter()
            .map(|at| at + clip.start as f32)
            .collect()
    }

    /// A clip's beats as the lane draws them.
    pub fn beats_path(&self, clip: &Clip) -> SharedString {
        let mut times = self.clip_beats(clip);
        if times.is_empty() {
            return SharedString::new();
        }
        for at in &mut times {
            *at -= clip.start as f32;
        }
        beats_commands(&times, clip.duration as f32, self.lanes.seconds_per_pixel).into()
    }

    /// Every beat of every clip not in `skip`: what a drag snaps to
    /// besides edges.
    pub fn beat_targets(&self, skip: impl Fn(&str) -> bool) -> Vec<f32> {
        self.timeline()
            .clips
            .iter()
            .filter(|clip| !skip(&clip.id))
            .flat_map(|clip| self.clip_beats(clip))
            .collect()
    }
}

#[cfg(test)]
mod beat_tests {
    use super::*;

    #[test]
    fn beats_land_on_the_timeline_by_the_clips_in_point_and_speed() {
        let beats = [0.5, 1.0, 1.5, 2.0, 2.5];
        // From 1.0 in, at normal speed, 1.2s long: 1.0 -> 0, 1.5 -> 0.5, 2.0 -> 1.0.
        assert_eq!(beat_times(&beats, 1.0, 1.0, 1.2), [0.0, 0.5, 1.0]);
        // At double speed the beats come twice as close.
        assert_eq!(beat_times(&beats, 0.0, 2.0, 1.0), [0.25, 0.5, 0.75, 1.0]);
        assert!(beat_times(&beats, 0.0, 0.0, 1.0).is_empty());
        assert!(beat_times(&beats, 9.0, 1.0, 1.0).is_empty());
    }

    #[test]
    fn the_beat_path_thins_to_a_bar_every_few_pixels() {
        let times: Vec<f32> = (0..100).map(|n| n as f32 * 0.01).collect();
        // A pixel just over a hundredth of a second: bars at least four
        // pixels (0.042s) apart, so every fifth beat.
        let path = beats_commands(&times, 1.0, 0.0105);
        assert_eq!(path.matches('M').count(), 20);
        assert!(path.starts_with("M0.000000 0 H0.010500 V1 H0.000000 Z "));
        assert!(beats_commands(&times, 0.0, 0.01).is_empty());
    }

    #[test]
    fn the_sidecar_sits_beside_the_sound() {
        assert_eq!(
            beats_file(std::path::Path::new("/p/audio/song.mp3")),
            std::path::PathBuf::from("/p/audio/song.beats.json")
        );
    }
}
