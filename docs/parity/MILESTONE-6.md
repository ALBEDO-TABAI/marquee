# 幕次-on-concat milestone 6

Recorded Asia/Tokyo, Sunday 8 Nov 2026 around 13:25–13:50 JST.

This pass closed every “still improvable” item listed at the end of `docs/parity/MILESTONE-5.md`, then recaptured the window so 小制片 can cut against a fuller shelf and inspector. Same standing constraints: AGPL fork in `.` only, no Jianying assets/keys/backends, no force-push, `CONCAT_GPU=software`, `DISPLAY=:11`, disk left at ~42 G free.

## What this milestone closed

1. **`presets.list` on the agent API.** `concat-cli api` now accepts `{ "method": "presets.list", "category": "huazi"|"template"|"language", "query": "…" }` and returns `{id, name, category, language, sample, path}`. Category is inferred from the id prefix (`marquee.huazi.*`, `marquee.tt.*`, else language). Query is a case-insensitive substring of id / name / sample. Unit test: `presets_list_filters_huazi_and_search`.
2. **Local HTTP API.** `scripts/marquee_http.py` proxies one `Session` on `127.0.0.1:8765`: `GET /health`, `GET /catalogue?kind=`, `GET /presets?category=&query=`, `POST /rpc`. Smoke on this box: health ok; 330 huazi; query `珊瑚` → 10 coral-* looks; 351 stickers; `version` → api 0.2 / concat 0.2.9.
3. **智能包装 beyond A+B.** `marquee-pack-wide` (三镜横屏包装, 1920×1080) and `marquee-pack-vertical` (三镜竖屏包装, 1080×1920) each have 4 slots (`slot-a`/`b`/`c` + `slot-music`) plus title, caption, sticker `marquee.ch01`, analog effect, two `marquee.blurxf` transitions and music (`volume` 0.35, fadeIn 0.4, fadeOut 0.6). Host tests: `builtin_smart_packs_are_listed` expects ≥ 42 packs; `builtin_layered_pack_parses` covers the wide recipe.
4. **Local Whisper, end-to-end.** `cargo run -p concat-speech --example transcribe` downloads `tiny.en` (~77 704 715 B) into `$XDG_DATA_HOME/app.marquee.editor/whisper-models/ggml-tiny.en.bin` (here `/tmp/marquee-xdg2/data/…`; not committed) plus Silero VAD `ggml-silero-v6.2.0.bin`. `espeak-ng` was not installable, so the public-domain whisper.cpp JFK sample was used instead of TTS. Both the wav and a muxed `speech.mp4` transcribed to the same two cues (see Captions below).
5. **Inspector IA.** Video sections are now 基础 / 蒙版 / 调节 / 动画 / 变速 / 增强 (`config-pane.slint` + zh-Hans: 基本→基础, 调整→调节, 速度→变速). 基础 shows 变换/画布/混合 without the cutout stack; 蒙版 shows 画布/混合/防抖/移除背景/自动抠像; 调节 is the colour panel; 动画 is a note that keyframes live on `setClipKey`; 变速 is `SpeedPanel` (恒定 / 曲线). Recaptured on a *video* clip (not a title).
6. **贴纸 order.** Media-pane sticker shelf defaults to packages (`sticker-shelf` 0), rail 贴纸 then 形状 — packages first, like JY.
7. **Every `marquee.*` SKU, once.** `scripts/marquee_agent.py sku` applied 1311 / 1311 catalogue packages (`effect`/`filter`/`sticker`/`textanim`/`transition`) across overlay tracks on top of 200 short video clips (1511 clips total). `failedCount` 0. Then a 1080p30 export. 花字 / 文字模板 were listed via `presets.list` (10 coral hits) but not individually applied — those are text presets, not catalogue packages.
8. **1080p30 + 1000+ clip stress.** See metrics. Software encode of the 16.00 s stacked timeline: 119.804 s, peak RSS **5 659 176 KiB (~5.4 GiB)**. No crash, no OOM.
9. **CPU card thumbnails.** 473 `preview.png` files (351 sticker + 122 textanim), 256×256 RGBA, ~2.6 MiB total, next to each package. `package_art` now falls back to `CARGO_MANIFEST_DIR/../concat-effects/packages/<id>/preview.png` when compiled-in packages have no `folder`. After rebuild, sticker and 文字动画 cards show the offline art under `CONCAT_GPU=software`.
10. **Audio.** `scripts/marquee_agent.py audio` imported a 220 Hz / 8 s stereo music wav and a 880 Hz / 0.35 s SFX wav (`media.probe` → pcm_s16le 44100 stereo), set fadeIn/fadeOut, ducked music with `setClipKey` volume 0.55→0.12 under the SFX window, exported 1280×720 30 fps with an AAC stereo track.

## Metrics

| Phase | Result | Clips / extras | Output | Build | Export | Total | Peak RSS |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: |
| sku | ok, 1311/1311 packages, 0 failures | 1511 clips, 1920×1080 30 fps, 16.00 s | `docs/parity/m6-demo/sku/m6-sku-1080p30.mp4` (11 478 945 B, h264 yuv420p bt709, 5737 kb/s) | 24.035 s | 119.804 s | 143.838 s | 5 659 176 KiB |
| audio | ok, fades + duck | music `m2`, sfx `m3`; 1280×720 30 fps, 8.00 s | `docs/parity/m6-demo/audio/m6-audio.mp4` (207 854 B, h264 + aac 48 kHz stereo) | — | — | 5.068 s | 408 988 KiB |

- Metrics JSON: `docs/parity/m6-demo/metrics.json`
- SKU stills: `docs/parity/m6-demo/sku/frames/t0.5.png`, `t4.0.png`, `t8.0.png` (colourful overlay blob — packages did composite), `t12.0.png`
- `presets.list category=huazi` → 330; `query=珊瑚` → 10

Rerun:

```bash
source /tmp/marquee-build.env
export CONCAT_GPU=software
python3 ./scripts/marquee_agent.py sku
python3 ./scripts/marquee_agent.py audio
python3 ./scripts/marquee_http.py --port 8765
```

## Captions (whisper.cpp `tiny.en`)

Source: official JFK wav (public domain) copied to `docs/parity/m6-demo/captions/jfk.wav` (352 078 B) and muxed to `speech.mp4` (531 606 B). Both produced:

```json
[
  {"start": 0.32, "end": 7.68, "text": "And so my fellow Americans ask not what your country can do for you"},
  {"start": 8.16, "end": 10.62, "text": "ask what you can do for your country."}
]
```

Files: `docs/parity/m6-demo/captions/segments-wav.json`, `segments.json`.

```bash
source /tmp/marquee-build.env
export XDG_DATA_HOME=/tmp/marquee-xdg2/data
cd ./src
cargo run -p concat-speech --example transcribe -- \
  ./docs/parity/m6-demo/captions/speech.mp4 tiny.en
```

There is still no `captions.transcribe` RPC (whisper stays out of `concat-cli` / `concat-api` on purpose).

## Window recapture (DISPLAY=:11, software GPU)

After wiring `preview.png` and rebuilding `marquee` (incremental, 8.2 s), the editor was relaunched on the M5 smoke project.

| State | Path |
| --- | --- |
| Inspector 视频 › 基础 (变换 / 画布 / 混合) | `docs/parity/m6-editor-inspector-basic.png` |
| Inspector 视频 › 蒙版 (画布 / 混合 / 防抖 / 抠像) | `docs/parity/m6-editor-inspector-mask.png` |
| Inspector 视频 › 调节 (colour knobs) | `docs/parity/m6-editor-inspector-adjust.png` |
| Inspector 视频 › 动画 (setClipKey note) | `docs/parity/m6-editor-inspector-animation.png` |
| Inspector 视频 › 变速 (恒定 / 曲线) | `docs/parity/m6-editor-inspector-speed.png` |
| 贴纸 (packages first, CPU card art) | `docs/parity/m6-editor-stickers.png` |
| 文本 › 文字动画 (CPU card art, 渐显入场 …) | `docs/parity/m6-editor-textanim.png` |
| 智能包装 (三镜横屏/竖屏 · 4 visible) | `docs/parity/m6-editor-smartpack.png` |

## Coverage now

| Panel | Count |
| --- | ---: |
| 花字 | 330 (`presets.list` category=`huazi`) |
| 文字模板 | 240 |
| 智能包装 | 42 (was 40) |
| 贴纸 | 351 |
| 文字动画 | 122 |
| `marquee.*` packages applied in sku | 1311 / 1311 |

## What remains (honest)

This is ready for 小制片 to exercise options and 包装, then file bugs. It is not a claim that the product is finished:

1. **No `captions.transcribe` RPC.** Transcription is the `concat-speech` example / Settings › 转录器 path. The model lives under XDG (~75 MiB) and must not be committed.
2. **No first-class duck / music ducking command.** Volume automation via `setClipKey` works and was verified; an agent has to write the keys.
3. **动画 section is a pointer, not JY’s full in/out animation page.** Keyframes already exist (`setClipKey` on opacity/scale/offset/rotation/volume). Building a visual keyframe editor is separate work.
4. **调节 labels** are still partly English (`Temperature`, `Tint`, `Saturation`…) while the section tab says 调节.
5. **花字 / 文字模板 were not each applied** in the sku pass — only listed and searched. Applying all ~570 text presets would be another timeline of titles.
6. **SKU 1080p export peak RSS ~5.4 GiB** on software GL. Fine on this box; a tighter machine may need a shorter overlay stack or a Vulkan GPU.
7. **Layered smart packs are two recipes**, not a full commercial catalogue of N-slot + music + sticker variants. Older packs remain A+B.
8. **HTTP API binds localhost only** and is a Python proxy. It is not authenticated and should not be exposed.
9. **Pixel match vs macOS Jianying refs** is still the wrong target; we will not copy JY chrome, fonts or assets to chase the stored ~96% masked number.
10. **Vendor ffmpeg on this box** has no `libx264` *name* in one invocation; default encode + `yuv420p` is what `make_clips` and the speech mux used. Engine export (sku/audio) produced valid High Profile H.264 anyway.

小制片 should start from `docs/AGENT-GUIDE.md`, keep one `concat-cli` (or `marquee_http.py`) process, set `CONCAT_GPU=software` on this box, and cut a real film against the shelves. Bugs found while cutting are the rest of “真正完善”.
