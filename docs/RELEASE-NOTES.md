# 幕次 (Marquee) — release notes for AGPL publication

This document summarises what the fork is, what the milestones added, and what
must be true before the tree is published. It does not replace `LICENSE`,
`LICENSING.md`, `ATTRIBUTION.md` or `TRADEMARK.md`.

Recorded Asia/Tokyo, 8 November 2026.

## What this is

幕次 (English: **Marquee**) is an **AGPL-3.0-or-later** desktop video editor,
an open fork of [Concat](https://github.com/jub0t/concat) by Jareer Abdullah
and Concat contributors. Engine crate names and JSON-RPC methods still say
`concat`; the product name, window title, `marquee` binary and icons do not.

This build is not Concat and must not be shipped under Concat’s name, logo or
marks (`TRADEMARK.md`). It is not Jianying and must not reuse Jianying assets,
proprietary fonts, minified original JY source, API keys or backends.

## Licence and notices to keep

- `LICENSE` — GNU AGPL-3.0-or-later (verbatim).
- `LICENSING.md` — upstream commercial option, retained; this fork is AGPL.
- `ATTRIBUTION.md` — names Concat, the licence, and the rebrand.
- `TRADEMARK.md` — Concat marks stay Concat’s; a modified distribution needs
  its own name (幕次 / Marquee) and icon.
- `THIRD_PARTY_NOTICES.md` and SPDX headers on source files.
- FFmpeg used at build time may be a BtbN LGPL shared build under
  `vendor/ffmpeg/` (not redistributed with the source tree; gitignored).

## README rebrand check

The top of `README.md` identifies 幕次 / Marquee and points at attribution,
licence and trademark files. The remainder is the **upstream Concat README**,
kept for engine history. Sponsor badges, Discord/download buttons, jsDelivr
Concat mark images and “Download Concat” artwork are upstream identity — do
not present them as this product. Ship the 幕次 icon
(`assets/icons/marquee_logo_*.png`) only.

## Do not publish

- Private user projects, tester films, or any machine-local project directories.
- Whisper model binaries (`ggml-*.bin`, `**/whisper-models/`).
- Local FFmpeg prefixes (`vendor/ffmpeg/`, `src/vendor/`).
- Evaluation encodes and caches (`docs/parity/**/*.mp4`, `docs/parity/**/cache/`,
  `docs-eval/`, `concat.lock`).
- Jianying logos, fonts, VIP/publish backends, or original JY assets.
- Secrets, API keys, or force-pushed history.

## Milestones

Work on this box was cut against a tester (小制片) who drove `concat-cli`
headlessly and compared behaviour with Jianying-style editing.

### M1–M4 — engine and first films

Local AGPL fork, rebrand (name, icons, binary `marquee`, XDG id
`app.marquee.editor`), JSON-RPC `concat-cli api`, software GPU path
(`CONCAT_GPU=software`), and the first scripted showcase / pack demos.

### M5 — smoke and stress

`scripts/marquee_agent.py` smoke and stress: many clips and tracks, catalogue
presets, titles, split/trim/move/undo/keyframes/speed/volume, then export.
Metrics under `docs/parity/m5-demo/` (caches not part of a source release).

### M6–M7 — sound, captions, ducking, presets

Audio mix, fades, `duckAudio` (four volume keys when the trigger overlaps the
bed). Local whisper.cpp captions (`captions.transcribe`), 花字/preset listing,
SKU and caption parity runs (`docs/parity/m6-demo/`, `m7-demo/`).

### M8 — first full tester cut (12 fixes)

The tester’s 78 s 1080p tokyo-day film. Fixes included probe/`catalogue.list`
empty-array behaviour, in-place `setClipSpeed` (`ripple: false`),
`updateClip` `patch.text` as a plain string, and related editorial bugs.
Retest notes: `docs/parity/m8-retest/`.

### M9 — round 2 (N1–N7)

- N1: `mask*` keys enable a **rectangle** mask, not a circle.
- N2: two-pass `loudnorm` + `alimiter` (broadcast dialogue target).
- N3: `copyClips` / `pasteClips` / `duplicateClips` (and singular aliases).
- N4: film grain / block noise / scanlines as luma-only (no RGB fringe).
- N5: sticker `addLayerClip` default scale **0.20**.
- N6: 42 smart-packs without the old teal chat slab.
- N7: models and dictionaries under XDG
  `~/.local/share/app.marquee.editor/` (or `$XDG_DATA_HOME/...`).
- Built-in Chinese homophone fixes and a user `captions-dictionary.json`.

### M10 — round 3 (B1–B3)

- B1: `duplicateClips` honours `start + offset`; a same-lane collision goes
  to a free/new track above (Jianying overlay behaviour) instead of sliding.
- B2: `placement` on `addClip` / `pasteClips` / `duplicateClips`:
  `overwrite` / `insert` / `newTrack` (default for programmatic overlays) /
  `error`. Every placing command returns `placed: [{clipId, trackId, start, end}]`
  and `warnings` when the clip moved. `addClip` at T2 0 s stays at 0 s.
- B3: glossary fuzzy (same-length n−1) is opt-in (`glossaryFuzzy`). Default
  matching is exact plus pinyin-equal, same-length, not crossing punctuation.

### M11 — round 4 polish (this release)

The tester signed off M10 and listed five leftovers:

1. **Glossary prompt bias.** Default glossary is post-correction only.
   `glossaryInPrompt` (default false) is required to append the list to
   whisper’s initial prompt (which could turn 开始响 into 开始想).
2. **简/繁.** Listing both writings of the same word no longer converts a
   correct cue into the other script; the post-pass detects the transcript’s
   script and keeps it.
3. **`setClipSpeed`** does not silently clear `speedCurve`. Pass
   `clearCurve: true` to replace a curve with a constant rate; otherwise the
   curve is kept and a warning is returned.
4. **`duckAudio`** with no overlap returns a warning and writes 0 keys
   (`applied: false`).
5. **Export loudness / AAC.** Second-pass offset compensation (+0.35 LU) and
   an alimiter at −1.2 dBTP aim integrated loudness closer to −14.0 LUFS
   while keeping true peak ≤ −1.0 dBTP after AAC. The apply pass resamples
   to 48 kHz and trims to the timeline duration so loudnorm upsampling and
   AAC padding do not leave a 96 kHz, 180.004 s mux.

## Talking to the engine

See `docs/AGENT-GUIDE.md` for JSON-RPC methods, `placement`, glossary flags,
export normalisation and the software-GPU build flags.

```bash
echo '{"method":"version"}' | concat-cli api
```

## Publication notes

The top-of-tree README now identifies 幕次, credits Concat, and documents
build/run steps with screenshots from `docs/parity` PNGs (not upstream Concat
download marks).

Local development history on this machine included evaluation MP4s, caches and
absolute project paths. Those objects were **not rewritten out of the existing
`main` branch**. The public GitHub repository is a clean export: full upstream
Concat history through the fork point, plus 幕次 commits that omit tester
media, evaluation movies, caches, locks, `docs-eval/`, `vendor/ffmpeg`,
downloaded Whisper bins, and machine-local paths.
