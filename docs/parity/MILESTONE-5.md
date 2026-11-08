# 幕次-on-concat milestone 5 (release candidate)

Recorded Asia/Tokyo, Sunday 8 Nov 2026 around 13:07–13:24.

This is the cut we want 小制片 to drive: every library shelf was opened in the window, the project/API layer built a long show and exported it, and another bot on this box can repeat that from `docs/AGENT-GUIDE.md` without touching the GUI.

## What this milestone closed

1. **Self-audit + smoke/stress.** `scripts/marquee_agent.py` keeps one `concat-cli api` process open, builds a project (create → import → tracks → clips → trim/split/move/undo/redo → speed/volume/keyframes → 花字 / 文字模板 / textanim / sticker / effect / filter / transition → long SRT → save → export) and records wall time, peak RSS and crashes. The GUI was then clicked through 媒体 / 音频 / 文本 / 花字 / 文字模板 / 文字动画 / 贴纸 / 转场 / 特效 / 滤镜 / 调节 / 字幕 / 智能包装 plus a selected-title inspector, the dense timeline and the 导出 dialog.
2. **Further UI chrome.** Library shelf tiles (`PresetGrid`, `ShelfGrid`, shapes, adjustment) `min-card` 88→108 so a typical left pane lands closer to Jianying’s four-column square cards; 智能包装 cards gained a 1px hover border; inspector chain-link padding 8→6px. Own brand only (accent still `#01B9C6`, name 幕次).
3. **Agent surface.** `docs/AGENT-GUIDE.md` documents env (`CONCAT_GPU=software`, `DISPLAY=:11`), the line-JSON RPC, project folder shape, `edit.apply` ops, how to instantiate 智能包装 and apply 花字/模板, and the helper script. `catalogue.list`’s invalid-kind error now names `sticker` and `textanim` (those kinds already worked).
4. **This file**, before/after and JY side-by-sides, stress metrics, demo export.

## Smoke and stress

Both phases exited 0. No crash. Renderer: software / llvmpipe. Export 854×480, 24 fps, CRF 28.

| Phase | Clips | Tracks | Duration | SRT cues | Build | Export | Total | Peak RSS | Output |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| smoke | 31 | 12 | 3.36s | 12 | 3.373s | 6.418s | 9.791s | 580 292 KiB (~567 MiB) | `docs/parity/m5-demo/smoke/m5-smoke.mp4` (182 177 B) |
| stress | **217** | 12 | **33.6s** | 90 | 3.857s | 27.737s | 31.594s | 599 604 KiB (~586 MiB) | `docs/parity/m5-demo/stress/m5-stress.mp4` (454 728 B) |

Applied catalogue ids (first `marquee.*` of each kind on this checkout): `marquee.analog` (effect), `marquee.alpine` (filter), `marquee.blurxf` (transition), `marquee.ch01` (sticker), `marquee.tacapblur` (textanim). Titles used 花字 `marquee.huazi.coral-outline` (珊瑚·描边), 文字模板 `marquee.tt.name-hot` (口播·人名条) and `marquee.tt.hook-hot` (热门·金句).

- Metrics: `docs/parity/m5-demo/metrics.json`
- Captions: `docs/parity/m5-demo/smoke/captions.srt`, `docs/parity/m5-demo/stress/captions.srt`
- Stress stills:

| Time | Path |
| --- | --- |
| 1.00s | `docs/parity/m5-demo/stress/frames/t1.00.png` (花字 + 人名条 + 字幕 004 + analog/sticker wash) |
| 5.00s | `docs/parity/m5-demo/stress/frames/t5.00.png` (solid clip after title window) |
| 12.00s / 20.00s / 28.00s | `docs/parity/m5-demo/stress/frames/t12.00.png` etc. |

Rerun:

```bash
source /tmp/marquee-build.env
export CONCAT_GPU=software
python3 ./scripts/marquee_agent.py          # both phases
python3 ./scripts/marquee_agent.py smoke
python3 ./scripts/marquee_agent.py stress   # merges into metrics.json
```

## Panel self-audit (window, stress project, DISPLAY=:11)

| Panel / flow | Result |
| --- | --- |
| 媒体 | Opens; six colour clips with duration badges; bin + timeline + preview painted. |
| 音频 | Opens to an empty “导入声音” well (this project has no audio files). Not a crash. |
| 文本 › 花字 | Four-column styled 花字 tiles (青釉 / 金箔 … 净色/描边/霓虹…). |
| 文本 › 文字模板 | 开场标题 / 人名条 cards across themes. |
| 文本 › 文字动画 | 122 names (渐显入场 …). Software GPU leaves these tiles as a “T” placeholder. |
| 贴纸 | 形状 grid first; scrolling reaches the 351 sticker packages (software GPU: document-icon placeholder, names visible). |
| 转场 / 特效 / 滤镜 | Category rail + artwork tiles (Exposure / Dissolve / Fresh …). |
| 调节 | Adjustment-layer card + hint about LUTs. |
| 字幕 | CaptionsForm: 文稿, 添加字幕, 导入/导出 SRT, 转写此片段的语音. Local Whisper still needs a model in Settings. |
| 智能包装 | Two-column recipe cards (横屏配方, 口播配方, 中轴配方, …) with size · slot count. |
| Inspector | Selecting 幕次·珊瑚 opens the 文本 inspector (内容 / 字体 / 大小 / 描边 / 布局 / 位置). |
| Timeline | 12 lanes, 217 clips, colour-coded bars, playhead, duration 00:00:33:17. Split/trim/move/undo/redo/speed/volume/keys exercised via API. |
| 导出 dialog | 1280×720 · 30 fps · H.264 · **217 个片段 · 93 个标题** · ~33s · 导出 ~2.2 MB. CLI export is the headless path (GUI button not pressed, to avoid a second encode). |

`catalogue.list` invalid `kind` used to mention only the original five kinds even though `sticker` / `textanim` already parsed — error text fixed.

## UI vs Jianying refs

Threshold 0.15 (max channel / 255), frames scaled to 1920×990 after dropping the 41px bottom XFCE panel. **Unmasked** full-frame scores are content-dominated (JY colour bars + sparse timeline vs our stress preview + 217 clips) and are *not* a chrome regression:

| Comparison | M4 media | M5 media |
| --- | ---: | ---: |
| Full vs `500_now` | 74.57% | 72.73% (518335 / 1900800) |
| Full vs `301_now` | — | 70.22% |
| Library well vs `500_now` | 90.56% | 83.35% (filled media cards) |
| Inspector vs `500_now` | 95.39% | **94.46%** (text inspector vs JY project chrome) |
| Timeline body vs `500_now` | 84.54% | 75.30% (expected: dense clips) |
| Tab strip vs `500_now` | 86.90% | 86.31% |

The M2 stored *masked* chrome figures (96.61% vs `500_now`, 97.41% vs `301_now`) still describe empty-preview alignment, not this filled RC screenshot. Structure (left rail + grid, centre preview, right inspector, bottom lanes) matches the JY workspace; pixel identity will not, because we will not copy JY assets, fonts or macOS chrome.

## Images to show 白

| State | Path |
| --- | --- |
| 媒体 (stress project, 217 clips) | `docs/parity/m5-editor-media.png` |
| Inspector (花字 selected) | `docs/parity/m5-editor-inspector.png` |
| 音频 | `docs/parity/m5-editor-audio.png` |
| 文本 › 花字 | `docs/parity/m5-editor-huazi.png` |
| 文本 › 文字模板 | `docs/parity/m5-editor-templates.png` |
| 文本 › 文字动画 | `docs/parity/m5-editor-textanim.png` |
| 贴纸 (scrolled to packages) | `docs/parity/m5-editor-stickers.png` |
| 转场 / 特效 / 滤镜 / 调节 | `docs/parity/m5-editor-{transitions,effects,filters,adjust}.png` |
| 字幕 | `docs/parity/m5-editor-captions.png` |
| 智能包装 | `docs/parity/m5-editor-smartpack.png` |
| 导出 dialog | `docs/parity/m5-editor-export.png` |
| M4 media \| M5 media | `docs/parity/m5_sbs_before_after.png` |
| JY 500_now \| M5 \| diff | `docs/parity/m5_sbs_vs_500_now.png` |
| JY 301_now \| M5 \| diff | `docs/parity/m5_sbs_vs_301_now.png` |
| JY 101_huazi \| 幕次 花字 | `docs/parity/m5_sbs_huazi.png` |
| Inspector crop | `docs/parity/m5_sbs_inspector.png` |
| Timeline crop | `docs/parity/m5_sbs_timeline.png` |
| Library crop | `docs/parity/m5_sbs_library.png` |
| Numbers | `docs/parity/MILESTONE-5-parity.json` |

## Coverage (unchanged catalogue counts from M4)

| Panel | 幕次 now |
| --- | ---: |
| 花字 | 330 |
| 文字模板 | 240 |
| 智能包装 | 40 |
| 贴纸 | 351 |
| 文字动画 | 122 |
| 转场 | 160 / 19 rails |
| 特效 | 585 |
| 滤镜 | 93 |
| Packages | 1439 (1311 `marquee.*` + 128 `concat.*`) |

## What is still improvable (honest)

This is a good RC for 小制片 to cut a real film against, not a claim that nothing else can be better:

1. **No HTTP API** — drive `concat-cli api` (one process) or `scripts/marquee_agent.py`. There is no `presets.list` RPC; agents read `src/crates/concat/text-presets/<id>/preset.toml` (the helper’s `read_preset()`).
2. **Software GPU** — `CONCAT_GPU=software` leaves some package cards undrawn (贴纸 art, many 文字动画 tiles). Timeline and preview still run on llvmpipe. A machine with Vulkan would look richer.
3. **智能包装** recipes are still A+B slot layouts, not full “title + effect + music” commercial packs.
4. **自动字幕** needs a local whisper.cpp model (Settings › 转录器). SRT import / `addTextClip` is the reliable agent path.
5. **Inspector IA** is Concat’s 文本 / 效果 / 音频, not Jianying’s 基础 / 蒙版 / 调节 / 动画 / AI玩法. Closing that gap is a large redesign, not a token tweak.
6. **Pixel match vs macOS JY refs** cannot honestly reach the stored ~96% masked number on a *filled* project, and we will not copy JY chrome to chase it. Remaining visual distance: fonts, title-bar widgets, playhead/ruler density, sticker card art.
7. **贴纸 tab** surfaces 形状 first; sticker packages sit below the fold.
8. **Stress coverage** applies the *first* `marquee.*` of each kind, not every SKU (that would be a multi-hour software encode). A 720p / 30 fps export of the same 33.6s timeline would be slower than the 854×480/24 probe.
9. **Long software exports** of much larger timelines (thousands of clips, 1080p) are unproven here; peak RSS on this 217-clip show stayed under ~600 MiB.

小制片 should start from `docs/AGENT-GUIDE.md`, keep one `concat-cli` process, set `CONCAT_GPU=software`, and file bugs against whatever breaks while cutting. That cooperation is the rest of “真正完善”.
