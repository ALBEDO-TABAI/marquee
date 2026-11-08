# 幕次-on-concat milestone 7

Recorded Asia/Tokyo, Sunday 8 Nov 2026 around 13:52–14:16 JST.

This pass closed every “still open” item listed at the end of `docs/parity/MILESTONE-6.md`. Same standing constraints: AGPL fork in `.` only (leave the sibling local checkout untouched), no Jianying assets/keys/backends, no force-push, `CONCAT_GPU=software`, `DISPLAY=:11`, disk left at ~39 G free after models and the SKU movie.

## What this milestone closed

1. **`captions.transcribe` RPC.** `concat-cli api` accepts `{ "method": "captions.transcribe", "file": "…", "model": "tiny.en"|"tiny"|"base"|"base.en"|"small"|"small.en", "language": "en"|"zh"|…, "sourceStart", "window" }` and returns `[{start,end,text}, …]`. `concat-api` now depends on `concat-speech`. Default model is `tiny.en`. Multilingual `base` (~142 MiB `ggml-base.bin`) was downloaded on this box into `/tmp/marquee-xdg2/data/app.marquee.editor/whisper-models/` (not committed) and used for Chinese.
2. **Chinese transcription.** gTTS produced `docs/parity/m7-demo/captions/zh-sample.wav` (“大家好，欢迎使用幕次。这是一段用来测试中文语音识别的示例。”). `captions.transcribe` with `model=base`, `language=zh` returned one cue. Recognition is usable but not perfect on TTS (`目次` for 幕次, `时别`/`势力` for 识别/示例) — expected for `base` + synthetic speech + an OOV product name.
3. **English transcription still works** through the same RPC: JFK (`docs/parity/m6-demo/captions/jfk.wav`, `tiny.en`) → the same two cues as M6.
4. **Native `duckAudio` command.** `{ "op": "duckAudio", "musicId", "triggerId", "amount": 0.15, "attack": 0.08, "release": 0.2 }` writes four `volume` keys on the music clip over the overlap with the trigger (attack before, release after). `scripts/marquee_agent.py audio` now uses this instead of hand-written `setClipKey`s. Export of `docs/parity/m6-demo/audio/m6-audio.mp4` succeeded (211 022 B this run).
5. **JY-style 动画 tab** for video and text: 入场 / 出场 (`none` / 渐显 / 上移 / 下移 / 左移 / 右移 / 放大) and 组合 (`none` / 脉冲 / 呼吸 / 浮动), each with a duration field. Stored on `clip.anim` (`intro`/`outro`/`combo` + `*Secs`). Flatten synthesizes opacity/transform keys (`fade`, `slide*`, `zoomIn`, `pulse`, `breathe`, `float`). This is a recipe tab that writes keys, not Jianying’s full visual animation editor or its package-driven 动画 market.
6. **调节 labels localized.** Inspector rows go through `i18n::t("adjust.{key}")` / `adjust.group.*`. zh-Hans: 色温 / 色调 / 饱和度 / 曝光 / … and group names 色彩 / 亮度 / 效果 / 色轮 / 曲线. `anim.*` keys cover the new tab. Other locales received the English key set so none are missing.
7. **Every 花字 and 文字模板 applied, 0 failures.** `python3 scripts/marquee_agent.py presets` listed 330 huazi + 240 templates = 570, applied each via `read_preset` + `addTextClip`. `failedCount` 0 in 8.013 s. This is an apply stress, not a 1080p encode of all 570 titles at once.
8. **1080p export memory: streaming/limits added, then re-measured.** Compositor now draws in waves of `LAYER_STREAM=24` (`stream_layers`) when a frame has more than 24 picture layers, and drops in-flight GPU plans to 1 in that case. The SKU timeline sequences overlays across 8 tracks (~8 concurrent layers per frame), so that path barely engages.
9. **SKU remasure.** Same 1311 / 1311 `marquee.*` packages + 200 shorts = 1511 clips, 1920×1080 @ 30 fps. Output `docs/parity/m7-demo/sku/m7-sku-1080p30.mp4` (11 478 945 B). Peak RSS **6 028 280 KiB (~5.75 GiB)** vs M6 **5 659 176 KiB (~5.4 GiB)**. No crash, no OOM. Memory did **not** drop: most of the RSS is the software (llvmpipe) exporter plus `concat-cli` now linking whisper, not a thousand layers in one pass.
10. **All 42 智能包装 are layered N-slot recipes.** Host tests (`builtin_smart_packs_are_listed`) require every pack to have ≥ 3 slots; wide/vertical stay at 4 (three pictures + music). Each recipe now carries title / caption / sticker / FX / transition / music tracks in the same pattern as the M6 三镜 packs.
11. **Localhost HTTP token.** `scripts/marquee_http.py` requires `--token` or `MARQUEE_HTTP_TOKEN` (else prints a generated hex). Accepted as `Authorization: Bearer`, `X-Marquee-Token`, or `?token=`. Smoke: no token → 401; all three carriers → 200 on `/health`; authenticated `POST /rpc` `version` → api 0.2 / concat 0.2.9.
12. **Editor restarted** on `DISPLAY=:11` with the final `src/target/debug/marquee` binary (pid recorded at launch 371087), `CONCAT_GPU=software`, `--project docs/parity/m5-demo/smoke`.

## Metrics

| Phase | Result | Extras | Output | Total | Peak RSS |
| --- | --- | --- | --- | ---: | ---: |
| presets | ok, 570/570 applied, 0 failures | 330 花字 + 240 文字模板 | `docs/parity/m7-demo/presets/presets` | 8.013 s | 91 316 KiB |
| captions | ok | JFK `tiny.en` (2 cues); zh `base` (1 cue) | `docs/parity/m7-demo/captions/` | 3.278 s | — |
| audio | ok, `duckAudio` | music under SFX amount=0.12 | `docs/parity/m6-demo/audio/m6-audio.mp4` (211 022 B) | 4.998 s | 413 160 KiB |
| sku | ok, 1311/1311 packages, 0 failures | 1511 clips, 1920×1080 30 fps | `docs/parity/m7-demo/sku/m7-sku-1080p30.mp4` (11 478 945 B) | 121.738 s (build 23.907 + export 97.831) | 6 028 280 KiB |

- Metrics JSON: `docs/parity/m7-demo/metrics.json`
- Captions detail: `docs/parity/m7-demo/captions/captions-report.json`
- zh sample: `docs/parity/m7-demo/captions/zh-sample.wav` (also `zh-sample.mp3`)

JFK (`tiny.en`):

```json
[
  {"start": 0.32, "end": 7.68, "text": "And so my fellow Americans ask not what your country can do for you"},
  {"start": 8.16, "end": 10.62, "text": "ask what you can do for your country."}
]
```

zh (`base`):

```json
[
  {"start": 0.23, "end": 8.22, "text": "大家好,欢迎使用目次,这是一段用来测试中文语音时别的势力。"}
]
```

Rerun:

```bash
source /tmp/marquee-build.env
export CONCAT_GPU=software
python3 ./scripts/marquee_agent.py presets
python3 ./scripts/marquee_agent.py captions
python3 ./scripts/marquee_agent.py audio
python3 ./scripts/marquee_agent.py sku
python3 ./scripts/marquee_http.py --token "$MARQUEE_HTTP_TOKEN" --port 8765
CONCAT_GPU=software DISPLAY=:11 \
  ./src/target/debug/marquee \
  --project ./docs/parity/m5-demo/smoke
```

## Tests built this pass

- `cargo test -p concat-project --lib`: 205 passed
- `cargo test -p concat-export --lib`: 30 passed (1 ignored)
- `cargo test -p concat-host --lib`: 143 passed (4 ignored), including the upgraded pack assertions
- `cargo build -p concat-cli` and `cargo build -p concat --bin marquee`

## What remains (honest)

M7 closed the M6 leftover list. Meaningful limits that are still true:

1. **动画 is recipes → keys, not JY’s full animation page.** No curve editor dedicated to 入场/出场, no browsing the 文字动画 market from that tab (that shelf already exists under 文本), no per-character 花字 animation beyond what flatten emits (`fade` / slides / `zoomIn` / `pulse` / `breathe` / `float`).
2. **1080p SKU peak RSS did not improve** (5.75 GiB vs 5.4 GiB). Layer streaming only helps a frame that actually stacks more than 24 pictures. This SKU does not. A tighter machine still needs a shorter overlay run or a real GPU; further cuts would mean retiring software-GL caches or not linking whisper into every `concat-cli` process.
3. **`duckAudio` writes four volume keys.** It is not a continuous sidechain compressor and will not track a moving voice automatically beyond the trigger clip’s span.
4. **HTTP token is a shared secret** for a localhost proxy. It is not sessions, TLS, or multi-user auth. Do not bind it off loopback.
5. **Flower-character stress did not 1080p-encode all 570 titles.** Apply succeeded with zero failures; encoding that stack is a different, memory-heavy job.
6. **Smart-pack upgrade is recipe structure**, not a new commercial catalogue of dozens of distinct designs.
7. **Chinese ASR quality** on `base` + TTS is imperfect; a cleaner mic recording would be a fairer test. Larger multilingual models (`small`) were not downloaded, to save disk.
8. **Pixel match vs macOS Jianying** is still the wrong target; we will not copy JY chrome, fonts or assets.
9. **Vendor ffmpeg** on this box still reports “Unknown encoder libx264” in some raw invocations; engine export writes valid High Profile H.264 via its own path.
10. **Whisper model bins** (~75 MiB `tiny.en` + ~142 MiB `base` + Silero VAD) live under XDG and must stay uncommitted. `concat-cli` now links whisper, so the agent CLI is heavier than in M6.

小制片 should start from `docs/AGENT-GUIDE.md`, keep one `concat-cli` (or token-guarded `marquee_http.py`) process, set `CONCAT_GPU=software` on this box, and cut a real film exercising 动画, 调节, 花字 / 文字模板 and 智能包装. Bugs found while cutting are the rest of “真正完善”.
