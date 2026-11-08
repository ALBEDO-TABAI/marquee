# 幕次-on-concat milestone 3

Recorded Asia/Tokyo, Sunday 8 Nov 2026 around 03:07–03:25.

## What closed vs old Marquee

1. **Stickers as concrete SKUs** — 351 browsable `kind = "sticker"` packages (was 11). Original SDF art only: 8 shapes × 8 colours × 4 motions = 256, plus 28 title frames, 28 chat bubbles and 28 deco frames. No JY IP, no copied Lottie/emoji sticker packs.
2. **Real per-glyph text animator** — layout now emits one reveal box per character (marks stay with their base). `frame.clip_duration` is written next to `clip_time` so in/out/loop shaders can time themselves. Every textanim shader reads `reveal_order(uv)` against clip-local progress. 122 items (was 70), toward 120+, on rails 入场 / 出场 / 循环 / 字幕动画 / 组合.
3. **Transitions as browsable SKUs** — 160 `marquee.*` transitions (was 29; 182 including upstream). All 19 JY rails have items: 热门, 最新, 基础, 叠化, 滑动, 缩放, 旋转, 模糊, 光效, 故障, 分割, 运镜, 拍摄, 旅行, 自然, 综艺, 表情, AI, 扭曲.
4. **Effect intensity variants** — each `marquee.*` effect family now has visible 25 / 45 / 65 / 85 items (468 variant packages) on the same JY rail as the parent, e.g. `marquee.grain25` … `marquee.grain85`.

## Coverage

| Panel | JY-shaped target | 幕次 now (`marquee.*`) | Notes |
| --- | ---: | ---: | --- |
| 贴纸 | ≥300 SKUs | **351** | Own SDF art; rails include 热门/涂鸦/Vlog/互动/面具/节日/情绪/… |
| 文字动画 | 70 → ~120+ | **122** | All shaders call `reveal_order`; demo typewriter reveals glyph-by-glyph |
| 转场 | ≥110, 19 rails | **160** / **19 rails** | Plus 22 upstream `concat.*` |
| 特效 | intensity copies per rail | **585** (117 families + **468** of 25/45/65/85) | Plus 24 upstream |
| 滤镜 | — | **93** | Unchanged this milestone |
| 花字 | — | **220** | Unchanged |
| 文字模板 | — | **216** | Unchanged |
| 智能包装 | — | **40** | Unchanged |

Built-in catalogue total: **1439** packages (1311 `marquee.*` + 128 `concat.*`).

## Demo export (concat exporter)

Via `concat-cli api` → `export.run` (CONCAT_GPU=software), 1280×720, 30 fps, 4.00s, 120 frames:

- Project: `docs/parity/m3-demo/showcase/` (title `c5` 花字 青焰·描边 look + `marquee.tacaptype`; sticker layer `marquee.sk000`; transition `marquee.xf000` 交叉溶解 over the cut at 1.5s; effect layer `marquee.grain65`)
- Output: `docs/parity/m3-demo/m3-showcase.mp4`
- Frame checks (typewriter visible: only 「幕次」 at 0.10s, full 「幕次花字 DEMO」 by 0.50s; sticker oval present; cut mixes then settles on clip B):

| Time | Path |
| --- | --- |
| 0.10s | `docs/parity/m3-demo/frames/t0.10.png` |
| 0.50s | `docs/parity/m3-demo/frames/t0.50.png` |
| 1.00s | `docs/parity/m3-demo/frames/t1.00.png` |
| 1.80s (mid transition) | `docs/parity/m3-demo/frames/t1.80.png` |
| 2.30s | `docs/parity/m3-demo/frames/t2.30.png` |
| 3.20s | `docs/parity/m3-demo/frames/t3.20.png` |

Also numbered `frames/frame_003.png` … `frame_096.png` (same instants).

## Parity

Editor chrome was not rebuilt this milestone. Re-ran the masked pixel match (threshold 0.15, 1920×990) on the M2 stills vs JY refs:

| Ref | Masked match |
| --- | --- |
| `jianying-research/ref/states/500_now.png` | **96.61%** |
| `jianying-research/ref/states/301_now.png` | **97.41%** |

See `MILESTONE-3-parity.json`.

## Tests

- `concat-effects --lib`: **78 passed** (including `marquee_stickers_are_concrete_skus`, `marquee_textanims_animate_glyphs_and_cover_the_rails`, `marquee_transitions_cover_jy_rails`, `marquee_effects_expose_intensity_variants`)
- `concat-text --lib`: **41 passed** (per-glyph boxes)
- `concat-host --lib` titles: **8 passed**; `builtin_smart_packs_are_listed` passed
- `concat-render` compiled with `frame.clip_duration`

Local commits only; no push; editor UI crate not rebuilt (avoids the prior rustc OOM).
