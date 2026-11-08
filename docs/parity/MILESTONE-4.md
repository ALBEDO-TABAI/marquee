# 幕次-on-concat milestone 4

Recorded Asia/Tokyo, Sunday 8 Nov 2026 around 12:37–13:02.

## What this milestone closed

1. **花字 and 文字模板 to Jianying-scale variety** — own designs only. 花字 grew from 220 to **330** (22 existing colorways + 11 new: 珊瑚 / 蜜桃 / 晴空 / 流沙 / 酒红 / 林深 / 象牙 / 菫青 / 钢青 / 蜂蜜 / 暮色, each × the 10 treats 净色/描边/厚描/霓虹/柔光/漫画/浮雕/叠影/长影/斜切). 文字模板 grew from 216 to **240** by adding layouts 金句 (`hook`) and 标签 (`badge`) across the 12 themes (JY-shaped targets were 322 and 233).
2. **UI chrome vs JY refs** — library tab strip 58→52px (matches the pane header comment), larger preset tiles (`min-card` 88→120), selected rail rows get a 2px accent bar, 文本 rail is now 花字 / 文字模板 / 语言 / 自动字幕 / 文字动画. Remaining user-visible `Concat` copy cleared in all 26 locale files (values only) plus default project folder, startup dialog and Windows ProductName.
3. **智能包装 and 字幕 end-to-end** — Templates page lists the 40 built-in recipes as clickable cards (`1920×1080 · 2`) and `use-template` fills slots from the current bin then opens the new project. Demo instantiated `口播配方` via `template.instantiate`. 字幕 tab is the existing CaptionsForm (稿件 / 添加字幕 / 导入·导出 SRT / 本地转写); SRT-style titles land as `addTextClip` the same way the importer does. Host test `builtin_talk_pack_parses` plus existing SRT unit tests pass.
4. **Docs** — this file, counts, parity %, before/after and JY side-by-sides, short demo export.

## Coverage

| Panel | JY-shaped target | 幕次 now | Notes |
| --- | ---: | ---: | --- |
| 花字 | 322 | **330** | 33 colorways × 10 treats; `marquee_huazi_ports_are_present` ok (incl. 珊瑚·描边) |
| 文字模板 | 233 | **240** | 20 layouts × 12 themes; hook-hot = 热门·金句, badge-min = 简约·标签 |
| 智能包装 | — | **40** | Gallery + instantiate; `builtin_smart_packs_are_listed` / `builtin_talk_pack_parses` ok |
| 贴纸 | ≥300 | **351** | Unchanged this milestone |
| 文字动画 | ~120+ | **122** | Unchanged |
| 转场 | ≥110 / 19 rails | **160** / **19** | Unchanged |
| 特效 | intensity copies | **585** | Unchanged |
| 滤镜 | — | **93** | Unchanged |

Built-in catalogue total still **1439** packages (1311 `marquee.*` + 128 `concat.*`). Text presets: 330 花字 + 240 文字模板 + shipped Latin defaults.

## 智能包装 + 字幕 demo export

Via `concat-cli api` → `template.instantiate` (口播配方, slots filled with clip-a / clip-b) then `addTextClip` (花字 珊瑚·描边 look + three SRT cues) → `export.run` (`CONCAT_GPU=software`), 1280×720, 30 fps, **7.00s**, 210 frames:

- Project: `docs/parity/m4-demo/pack-talk/`
- Captions source: `docs/parity/m4-demo/captions.srt`
- Output: `docs/parity/m4-demo/m4-showcase.mp4`
- Frame checks (coral title throughout; caption line changes; cut to clip B after 4s):

| Time | Path |
| --- | --- |
| 0.20s | `docs/parity/m4-demo/frames/t0.20.png` |
| 1.00s | `docs/parity/m4-demo/frames/t1.00.png` |
| 2.50s | `docs/parity/m4-demo/frames/t2.50.png` |
| 4.50s | `docs/parity/m4-demo/frames/t4.50.png` |
| 5.50s | `docs/parity/m4-demo/frames/t5.50.png` |
| 6.60s | `docs/parity/m4-demo/frames/t6.60.png` |

## Editor screenshots (show 白)

| State | Path |
| --- | --- |
| 媒体 (demo project, library cards + timeline + inspector) | `docs/parity/m4-editor-media.png` |
| 文本 › 花字 | `docs/parity/m4-editor-huazi.png` |
| 文本 › 文字模板 | `docs/parity/m4-editor-templates.png` |
| 文本 › 自动字幕 | `docs/parity/m4-editor-captions.png` |
| 智能包装 gallery | `docs/parity/m4-editor-smartpack.png` |
| M2/M3 before \| M4 after | `docs/parity/m4_sbs_before_after.png` |
| JY 500_now \| M4 \| diff | `docs/parity/m4_sbs_vs_500_now.png` |
| JY 301_now \| M4 \| diff | `docs/parity/m4_sbs_vs_301_now.png` |
| JY 101_huazi \| 幕次 花字 | `docs/parity/m4_sbs_huazi.png` |

## Parity

Threshold 0.15 (max channel / 255), frames scaled to 1920×990.

M2/M3 stored alignment (preview / library cards / timeline / clock already painted out on those stills):

| Ref | M2/M3 stored |
| --- | --- |
| `jianying-research/ref/states/500_now.png` | **96.61%** (64388 / 1900800) |
| `jianying-research/ref/states/301_now.png` | **97.41%** (49218 / 1900800) |

Same JY stills vs a geometric chrome mask (library well, preview, timeline body, clock) so rail / tab strip / inspector / title stay in the score. The M4 still is a filled 口播配方 project, so unmasked content (preview picture, timeline clips) is *not* what this row measures:

| Ref | Before (same mask) | After (M4) |
| --- | ---: | ---: |
| 500_now | 91.30% | **91.27%** (51619 / 591100) |
| 301_now | 94.02% | **93.94%** (35819 / 591100) |

Region vs 500_now (unmasked strip):

| Region | Before | After |
| --- | ---: | ---: |
| Left rail | 90.62% | **91.38%** |
| Inspector | 95.42% | 95.14% |
| Tab strip | 84.15% | 84.17% |

Chrome held. Rail picked up a little from the 52px header, 120px tiles and selected-row accent. Inspector/title numbers move slightly because the after shot is `pack-talk` rather than the empty `幕次 试片` project. Raw numbers also in `docs/parity/MILESTONE-4-parity.json`.

## Branding

- 26 locale files: 0 remaining `Concat` *values* (keys such as `settings.concat` / `start.notConcatProjectFolder` kept).
- Default new-project folder is `幕次` (was `Concat`) on desktop / Documents.
- Startup failure dialog title and Windows `ProductName` / `FileDescription` say 幕次.
- Upstream GitHub URLs and SPDX “Concat contributors” lines left as attribution.

No Jianying assets, no backend calls, AGPL notices untouched, the sibling local checkout untouched, no push.
