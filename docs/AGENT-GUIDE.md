# 幕次 agent guide

How another agent drives 幕次 headlessly to edit and export a film.
Recorded Asia/Tokyo, 8 Nov 2026.

The product name is **幕次**. The engine, crate names and JSON-RPC methods still say `concat` (AGPL fork of jub0t/concat). Do not ship Concat branding; do not call Jianying backends or copy Jianying assets.

## Environment

```bash
# Optional: source a local env file that sets FFMPEG_DIR / PKG_CONFIG_PATH / clang.
export CONCAT_GPU=software             # use this without Vulkan
# export DISPLAY=:0                    # only needed if you also open the window
```

Binaries (dev build, not shipped):

| Binary | Path |
| --- | --- |
| JSON-RPC CLI | `src/target/debug/concat-cli` |
| Editor window | `src/target/debug/marquee` |
| Helper | `scripts/marquee_agent.py` |
| Local HTTP proxy | `scripts/marquee_http.py` |

`--project` and `--software` are mutually exclusive on the window; use `CONCAT_GPU=software` with `--project`. Rebuild after engine changes:

```bash
cd src
CARGO_BUILD_JOBS=2 CARGO_PROFILE_DEV_DEBUG=0 cargo build -p concat-cli
# window / Slint (slow, memory-hungry):
CARGO_BUILD_JOBS=2 CARGO_PROFILE_DEV_DEBUG=0 cargo build -p concat --bin marquee
```

## Talking to the engine

`concat-cli api` speaks **one JSON object per line** on stdin, one reply (or event) per line on stdout.

```bash
echo '{"method":"version"}' | concat-cli api
```

A bare `{"method":"…", …}` works (no JSON-RPC envelope required).

**Keep one process open for the whole session.** A project is only loaded inside that process. A second `concat-cli api` invocation does not see it (`notOpen`). The helper does this for you.

```python
# scripts/marquee_agent.py
from pathlib import Path
import runpy
# or: python3 scripts/marquee_agent.py smoke
```

```python
from scripts.marquee_agent import Session   # if you put the folder on sys.path
s = Session()
s.call("project.create", location="/tmp/films", name="take-1",
       video={"width": 1280, "height": 720, "rateNum": 30, "rateDen": 1})
```

`export.run` returns at once with a job id; progress arrives as notifications:

```json
{"method":"export.progress","params":{"job":"j1","frame":15,"total":120,"stage":"rendering"}}
{"method":"export.done","params":{"job":"j1","output":"/path/out.mp4","width":1280,"height":720}}
{"method":"export.failed","params":{"job":"j1","message":"…"}}
```

Wait until `export.done` or `export.failed`. `Session.export_and_wait` does that.

## RPC methods

| Method | Purpose |
| --- | --- |
| `version` | Build + api version + config dirs |
| `project.create` | `location`, `name`, optional `video` `{width,height,rateNum,rateDen}` |
| `project.open` / `project.close` | `path` (close may `save`) |
| `project.get` | Editor view: `{project, settings, canUndo, canRedo, createdId?}` |
| `project.document` | Raw save document (no `project` wrapper) |
| `project.save` | `path`, optional `name` |
| `project.setVideo` | Undoable frame/rate change |
| `project.list` | Recents |
| `media.import` | `path` (project) + `file` (absolute media). Returns `createdId` (`m1`…) |
| `media.probe` | Inspect a file without importing. Param is `path` (absolute file); `file` is accepted as an alias. |
| `catalogue.list` | Optional `kind`: `effect`, `filter`, `audio`, `transition`, `generator`, `sticker`, `textanim` |
| `presets.list` | Text presets (花字 / 文字模板 / 语言). Optional `category` (`huazi` \| `template` \| `language`) and `query` (case-insensitive substring of id, name or sample). Reply is a JSON array of `{id, name, category, language, sample, path}`. |
| `captions.transcribe` | Local whisper.cpp. `file` (absolute wav/mp4/…), optional `model` (`tiny.en` default; multilingual `small` when `language` is `zh` and `model` is omitted; also `tiny` / `base` / `base.en` / `small.en`), optional `language` (`en`, `zh`, …), optional `prompt` (initial prompt; Chinese defaults to a Simplified-Chinese + punctuation hint), optional `glossary` (string array of hotwords used by **post-correction only** by default: exact + pinyin-equal same-length substitutions that do not cross punctuation, and that keep the transcript’s 简/繁 script when both forms are listed), optional `glossaryInPrompt` (default **false**; when true, also appends the list to whisper’s initial prompt — this can bias a same-pinyin syllable such as 开始响→开始想), optional `glossaryFuzzy` (default **false**; the old same-length n−1 character substitution, which rewrote neighbouring words such as 很小声→很轻声). A user dictionary at `~/.local/share/app.marquee.editor/captions-dictionary.json` (or `$XDG_DATA_HOME/app.marquee.editor/captions-dictionary.json`) of `{"wrong":"right"}` is applied after decode. VAD (Silero) is on. Chinese uses beam 5. Downloads `ggml-<model>.bin` into `$XDG_DATA_HOME/app.marquee.editor/whisper-models/` when `XDG_DATA_HOME` is an absolute path, otherwise **`~/.local/share/app.marquee.editor/whisper-models/`** (`small` ~466 MiB). Reply is `[{start,end,text}, …]`. Do not commit the model bins. |
| `template.list` | Built-in 智能包装 + user templates (`name`, `path`, `slots`, `width`, `height`) |
| `template.instantiate` | `template`, `location`, `name`, `fills: [{mediaId, file}]` — **all slots required** |
| `template.save` | Pack the open project |
| `edit.apply` | `path` + `command` `{op, …}` |
| `edit.undo` / `edit.redo` | `path` |
| `export.run` | `path`, `output`, optional `crf`, `preset`, `width`, `height`, `rateNum`, `rateDen`, `codec`, `normalize` (default **true**: two-pass loudnorm `I=-14`, `TP=-1.5` dBTP, `LRA=11`, `linear=true` with measured_* from a first pass and a +0.35 LU offset compensation, then `alimiter` at −1.2 dBTP, resampled to 48 kHz and trimmed to the timeline duration so AAC does not pad extra samples). Target: integrated near −14.0 LUFS, true peak ≤ −1.0 dBTP. Pass `normalize: false` to skip. |
| `export.status` / `export.cancel` | Job |
| `preview.frame` | One composited frame |

Created ids come back as `createdId` on the view (`m…` media, `c…` clips, `t…` tracks). Placing commands also return `placed: [{clipId, trackId, start, end}, …]` with the lane and span each clip actually occupies, and `warnings` when a clip was moved to another track or time.

`catalogue.list` with `kind: "generator"` currently returns an empty JSON array `[]` (no generator packages yet). `scripts/marquee_agent.py` `Session.call` keeps that array: it returns `reply["result"]` even when the result is `[]`, and does not coerce empty lists to `{}`.

## Project file format

A project is a **folder** containing `concat.json` (and caches). Important fields, camelCase:

```json
{
  "name": "take-1",
  "video": {"width": 1280, "height": 720, "rateNum": 30, "rateDen": 1},
  "media": [{"id": "m1", "path": "/abs/clip.mp4", "name": "clip.mp4",
             "duration": 2.0, "kind": "video", "width": 1280, "height": 720}],
  "timelines": [{
    "id": "TL1",
    "name": "Timeline 1",
    "tracks": [{"id": "T1", "visible": true, "muted": false}],
    "clips": [{
      "id": "c3", "trackId": "T1", "mediaId": "m1", "kind": "video",
      "start": 0.0, "duration": 2.0, "sourceStart": 0.0,
      "volume": 1.0, "opacity": 1.0, "speed": 1.0,
      "anim": {"intro":"fade","introSecs":0.4,"outro":"slideUp","outroSecs":0.4,"combo":"pulse","comboSecs":1.0},
      "filters": [], "videoEffects": []
    }]
  }],
  "activeTimelineId": "TL1"
}
```

Some older 智能包装 recipes still store top-level `tracks` / `clips`; the engine migrates them on read.

Kinds you will see on clips: `video`, `audio`, `image`, `text`, `shape`, `layer`, `transition`, `soundLayer`.

## Useful `edit.apply` ops

Every command is `{ "op": "<camelCase name>", ... }`.

| op | Notes |
| --- | --- |
| `addMedia` | Prefer `media.import` (it probes). |
| `addClip` | `mediaId`, `trackId`, `start`, optional `ripple`, optional `placement` (`overwrite` / `insert` / `newTrack` / `error`). When `placement` is omitted, `ripple: true` (bin drop) is `insert`; otherwise the default is `newTrack`: the clip keeps the asked time and, if that span is taken, lands on a free lane above or a newly minted top track (Jianying overlay behaviour) instead of sliding later on the same lane. So `addClip` onto T2 at 0 s lands at 0 s even if T2 already has a sticker from 1–6 s. `overwrite` trims/splits occupants; `insert` ripples later clips; `error` refuses with “That place is already occupied.” |
| `addClipAtFirstFree` | `mediaId`, `start` |
| `addClipsInSequence` | `mediaIds`, `start`, optional `trackId`, `ripple` |
| `addTextClip` | `start`, optional `trackId`, `above`, `duration`, `offsetY`, `style` |
| `addShapeClip` | Same placement + `name`, optional `style` |
| `addLayerClip` | `start`, `effectId`, `name`, optional `duration`, `trackId`, `sound`, `scale`. Sticker packages (`sk`/`ti`/`de`/`ch`/`st` prefix after the last dot) default to scale **0.20** (Jianying-sized, about 0.18–0.22); effects/filters stay 1.0. Pass `scale: 1.0` to force full-frame. |
| `addTransitionClip` | `start`, `transitionId`, `name`, optional `duration` |
| `updateClip` | `clipId`, `patch` (only set fields change): `volume`, `opacity`, `filters`, `videoEffects`, `name`, `muted`, `fadeIn`, `fadeOut`, `text` (full style object, **or a plain string** rewriting `content`, or `null` to clear), `anim` (`intro`/`outro`/`combo` plus `introSecs`/`outroSecs`/`comboSecs`)… |
| `trimClip` | `clipId`, `edge`: `"start"` \| `"end"`, `delta` seconds (sign: tail `+` lengthens), optional `ripple` |
| `splitClips` | `clipIds`, `time` (timeline seconds) |
| `moveClips` | `moves: [{clipId, start, trackId}]` |
| `removeClips` | `clipIds`, optional `ripple` |
| `copyClips` / `copyClip` | `clipIds` and/or `clipId`. Copies onto an in-memory project clipboard (not saved, not an undo step). |
| `pasteClips` / `pasteClip` | Optional `start` (leftmost pasted clip), `trackId`, and `placement` (default `newTrack`). One undo step. Empty clipboard is a no-op. An overlap keeps the asked time and moves to a free/new track above rather than silently sliding. |
| `duplicateClips` / `duplicateClip` | `clipIds` and/or `clipId`, optional `offset` seconds (default 1.0), optional `placement` (default `newTrack`). The copy is placed at original `start + offset` (a clip at 8 s with `offset: 2` lands at 10 s). If that span collides on the same lane, the copy goes to a free lane above or a new top track, with a warning — it is not slid later on the original lane. One undo step. |
| `setClipSpeed` | `clipId`, `speed` (0.0625–16), optional `ripple` (default **false**), optional `clearCurve` (default **false**). Does **not** silently drop an existing `speedCurve`; it keeps the curve and returns a warning. Pass `clearCurve: true` to replace the curve with a constant rate. `ripple: false` is in-place (Jianying 不变时长). `ripple: true` retimes duration to source/speed and slides neighbours (magnetic). The same ripple flag exists on `setClipSpeedCurve`. |
| `setClipKey` | `clipId`, `property` (`opacity`, `scale`, `offsetX`, `offsetY`, `rotation`, `volume`, `maskX`…), `at` 0–1, `value`. A `mask*` key on a clip that has no mask yet enables a default rectangle mask, so the key is visible in preview/export. |
| `duckAudio` | `musicId`, `triggerId`, optional `amount` (default 0.15), `attack` (0.08), `release` (0.2). Writes **four** `volume` keys (down, ducked, ducked, up) when the clips overlap. If they do not overlap the command succeeds with `applied: false`, **0 keys**, and a warning. Keys closer than `KEY_EPSILON` (0.002 of clip length) are spread so a short attack on a long music clip (e.g. 0.12s on 78s) is not collapsed. |
| `clearClipKey` / `clearClipKeys` | Remove one or all keys on a property |
| `setClipTransform` | Scale / offset / rotation in one step |
| `addTrack` | Optional `bottom: true` |
| `removeTrack` | `trackId` (cannot delete the last lane) |
| `setTrackFlag` | `trackId`, `flag`: `"visible"` \| `"muted"`, `value` |
| `batch` | `commands: [ … ]` as one undo step |

Applying a look to a clip (wholesale chain replace):

```json
{"op":"updateClip","clipId":"c3","patch":{
  "videoEffects":[{"id":"marquee.grain65","enabled":true,"params":{}}],
  "filters":[{"id":"marquee.<filter>","enabled":true,"params":{}}]
}}
```

A sticker, filter-as-layer, or effect over a span is an `addLayerClip`. A transition sits on the cut as `addTransitionClip` (duration typically 0.6–1.0s, start near the cut).

A title from a 花字 / 文字模板: copy `[style]` out of `src/crates/concat/text-presets/<id>/preset.toml` into `addTextClip.style`, then set `content` to the words you want. `scripts/marquee_agent.py` has `read_preset()`.

A 文字动画 is a `textanim` package on the *title* clip’s `videoEffects` (not on the video). `marquee.tainfade` finishes every glyph (including the last character of e.g. 「午前的光」) at progress=1, and display-space textanims no longer fringe the layer underneath with chroma on transparent pixels. `marquee.grain*` / `blocknoise*` / `scanlines*` are monochrome (luma) treatments; named chromatic families (`rgbsplit*`, `chromatic*`, `vhs*`, …) still split RGB on purpose.

字幕: the window’s “导入 SRT” turns each cue into `addTextClip` (above, short duration, caption look). There is still no `captions.import`; write those `addTextClip` commands yourself. Speech-to-text is `captions.transcribe` (same `Transcriber` the GUI uses). Models download into **`~/.local/share/app.marquee.editor/whisper-models/`** by default (`ggml-tiny.en.bin` ~75 MiB, multilingual `ggml-base.bin` ~142 MiB, multilingual `ggml-small.bin` ~466 MiB). If `XDG_DATA_HOME` is set to an absolute path, they go to `$XDG_DATA_HOME/app.marquee.editor/whisper-models/` instead. A relative `XDG_DATA_HOME` is ignored. Do not commit the `.bin` files.

```bash
echo '{"method":"captions.transcribe","file":"/path/speech.wav","model":"tiny.en","language":"en"}' | concat-cli api
echo '{"method":"captions.transcribe","file":"/path/zh.wav","language":"zh"}' | concat-cli api
# language=zh with no model downloads/uses multilingual `small` and a Simplified-Chinese punctuation prompt.
# Pass `"model":"base"` to keep the smaller multilingual model.
# glossary / 专有词汇 (hotwords) plus optional user dictionary.
# Default: post-correction only (do not inject the list into the whisper prompt).
# Same-length n−1 “fuzzy” substitution is opt-in (`glossaryFuzzy: true`).
# Prompt injection is opt-in (`glossaryInPrompt: true`) — leave it off to avoid
# biasing 开始响→开始想. Prefer one script in the list, or list both: the
# post-pass keeps the transcript’s 简/繁.
# echo '{"method":"captions.transcribe","file":"/path/zh.wav","language":"zh","glossary":["绣球","电线杆"]}' | concat-cli api
```

Verified: JFK (`docs/parity/m6-demo/captions/jfk.wav`) with `tiny.en`, and a gTTS Chinese sample (`docs/parity/m7-demo/captions/zh-sample.wav`) with multilingual models (`base` / `small`). Prefer `small` + the default zh prompt for production Chinese.

智能包装: `template.list` then `template.instantiate` with a file for every `slots[].mediaId`. All 42 built-ins are layered N-slot recipes (at least video A/B + music; **三镜横屏包装** / **三镜竖屏包装** add a third picture slot). They also drop a title (cream/ink/rust, fontSize about 0.042–0.050), a caption (smaller, translucent black plate), a small static sticker (scale ~0.18–0.22, corner placed; not the cyan `marquee.ch01` chat slab), a restrained full-frame grain FX layer, `marquee.blurxf` cuts and music (`volume` 0.35, fadeIn 0.4, fadeOut 0.6). Instantiate already opens the project in the same session.

## Catalogues on disk (this checkout)

| Kind | Where / how to list |
| --- | --- |
| 花字 | `src/crates/concat/text-presets/marquee.huazi.*/preset.toml` (330) |
| 文字模板 | `…/marquee.tt.*/preset.toml` (240) |
| 贴纸 / 特效 / 滤镜 / 转场 / 文字动画 | `catalogue.list` (`sticker`, `effect`, `filter`, `transition`, `textanim`) |
| 智能包装 | `template.list` or `src/crates/concat-host/smart-packs/*/template.json` (42; every recipe is layered: ≥3 slots, titles/stickers/FX/music; wide/vertical have 4 slots) |

Prefer `marquee.*` ids (our designs). `concat.*` are upstream packages.

## Window, if you need to look

```bash
CONCAT_GPU=software DISPLAY=:11 \
  src/target/debug/marquee \
  --project /abs/path/to/project-folder
```

`CONCAT_GPU=software` still composites the timeline and preview on llvmpipe (shader-rendered cards stay skipped). Sticker and textanim shelves now load CPU-rendered `preview.png` sidecars from `src/crates/concat-effects/packages/<id>/preview.png` even for compiled-in packages (`folder` is unset).

## Smoke and stress

```bash
python3 scripts/marquee_agent.py smoke
python3 scripts/marquee_agent.py stress
python3 scripts/marquee_agent.py sku       # every marquee.* package + 1080p30
python3 scripts/marquee_agent.py audio     # music/SFX import, fades, duckAudio
python3 scripts/marquee_agent.py presets   # apply every 花字 + 文字模板
python3 scripts/marquee_agent.py captions  # captions.transcribe (en + zh if present)
```

With no arguments `smoke` and `stress` run (M5). `stress` builds 120 trimmed clips (217 clips once titles/layers/splits are counted), extra tracks, one preset from every catalogue kind, ~90 SRT titles, split/trim/move/undo/redo/keyframes/speed/volume, then exports. A smoke/stress rerun merges into `docs/parity/m5-demo/metrics.json` by phase name. `sku` / `audio` / `presets` / `captions` write `docs/parity/m7-demo/metrics.json` (M6 kept its own copy).

`sku` lays ~200 short video clips plus every `marquee.*` catalogue package (`effect` / `filter` / `sticker` / `textanim` / `transition`) across overlay tracks, calls `presets.list`, and exports 1920×1080 @ 30 fps. Overlays are sequenced (~8 concurrent layers per frame, not 1311 stacked at once). Peak RSS on this box in M7 was about 5.75 GiB (M6 was ~5.4 GiB) — give the process room. Export composites in waves of 24 layers when a single frame exceeds that (`LAYER_STREAM`); that path does not shrink this particular SKU.

## Local HTTP API

`scripts/marquee_http.py` keeps one `Session` (one `concat-cli`) and listens on `127.0.0.1:8765` by default. It is a stdlib proxy. Every route needs a shared token (`--token`, else `MARQUEE_HTTP_TOKEN`, else a generated hex printed at startup), sent as `Authorization: Bearer …`, `X-Marquee-Token`, or `?token=`. This is a localhost shared secret, not a real auth system. `concat-cli` itself now links whisper so `captions.transcribe` works through `/rpc` as well.

```bash
export MARQUEE_HTTP_TOKEN=…   # or pass --token
python3 scripts/marquee_http.py --port 8765
curl -s -H "Authorization: Bearer $MARQUEE_HTTP_TOKEN" http://127.0.0.1:8765/health
curl -s -H "X-Marquee-Token: $MARQUEE_HTTP_TOKEN" 'http://127.0.0.1:8765/catalogue?kind=sticker'
curl -s "http://127.0.0.1:8765/presets?category=huazi&query=珊瑚&token=$MARQUEE_HTTP_TOKEN"
curl -s -X POST http://127.0.0.1:8765/rpc \
  -H "Authorization: Bearer $MARQUEE_HTTP_TOKEN" -H 'Content-Type: application/json' \
  -d '{"method":"version"}'
```

GET `/presets` and `/catalogue` return the raw arrays. POST `/rpc` takes `{ "method": "...", ... }` and replies `{ "result": ... }`. Bind only to localhost. A missing/wrong token is `401 {"error":"unauthorized"}`.

## M11 (round-4 polish)

- Caption `glossary` is post-correction only by default (`glossaryInPrompt` opt-in). Pinyin-equal replace keeps the source 简/繁 script when both forms are listed.
- `setClipSpeed` keeps `speedCurve` unless `clearCurve: true`.
- `duckAudio` warns and writes 0 keys when music and trigger do not overlap.
- Export loudnorm aims closer to −14.0 LUFS (offset compensation + limiter −1.2 dBTP) and re-encodes AAC at 48 kHz trimmed to the timeline duration.

## M10 (round-3 fixes)

- `duplicateClips` honours `start + offset`. A collision uses `placement` (default `newTrack`) instead of silently sliding the copy later on the same lane.
- `addClip` / `pasteClips` / `duplicateClips` accept `placement`: `overwrite`, `insert`, `newTrack` (default for programmatic overlays), `error`. Every placing command reports `placed` and, when the clip did not keep the asked lane or time, `warnings`.
- Caption `glossary` no longer applies same-length fuzzy substitution by default (`glossaryFuzzy` opt-in). Default matching is exact plus pinyin-equal, same-length, not crossing punctuation.

## M9 (round-2 fixes)

- Auto-enabled masks from `mask*` keys are **rectangle** (`ClipMask::of(MaskShape::Rectangle)`), not circle.
- Export loudness is two-pass `loudnorm` + `alimiter` (target −14 ±0.5 LUFS, TP ≤ −1.0 dBTP).
- JSON-RPC clipboard: `copyClips` / `pasteClips` / `duplicateClips` (and singular aliases), including multi-select; paste/duplicate are one undo step.
- Software 1080p export speed: raising `IN_FLIGHT` from 2 to 6 *slowed* the 3-min film (~225 s → ~300 s on llvmpipe); the overlap stays at 2.
- Sticker default scale is **0.20**. Smart-pack cards use varied, restrained palettes and JY-sized stickers.

## Constraints

No Jianying assets, fonts, or network backends. No force-push. Watch disk (`src/target` is large); `CARGO_BUILD_JOBS=2` and `CARGO_PROFILE_DEV_DEBUG=0` when rebuilding the UI crate.
