# 幕次-on-concat milestone 2

Recorded Asia/Tokyo, Sunday 8 Nov 2026 around 02:58–03:06.

## Rebrand

- User-visible `Concat` copy in `locales/en.json` and `locales/zh-Hans.json` is now 幕次 (30 strings each).
- App identifier is `app.marquee.editor`. Settings folders named `app.concat.editor` or `org.standalones.concat` are adopted on first launch.
- Desktop binary rebuilt: start page reads **欢迎使用 幕次**. `--version` still `幕次 0.2.9 (fork of Concat)` (attribution).
- Android/iOS/`app.concat.editor.spike` JNI identifiers were left alone.

## Screenshots

- `marquee_start_screen.png` — 欢迎使用 幕次
- `marquee_editor_running.png` — editor chrome, JY tab set
- `sbs_vs_500_now.png` / `sbs_vs_301_now.png` — JY | 幕次 | diff after chrome mask

## Parity (masked pixel match, threshold 0.15, both frames scaled to 1920×990)

Masked regions: preview, library cards, timeline, clock. Layout chrome is what remains.

| Ref | Masked match |
| --- | --- |
| `jianying-research/ref/states/500_now.png` | **96.61%** |
| `jianying-research/ref/states/301_now.png` | **97.41%** |

## Coverage

| Panel | JY observed items | 幕次 now | Notes |
| --- | ---: | ---: | --- |
| 特效 families | 535 (incl. intensity copies) | **117** `marquee.*` effect packages | One package per shader family + amount slider (not 4 intensity clones). Plus 24 upstream `concat.*` effects. |
| 滤镜 | (15 rails) | **93** `marquee.*` filters | 90 generated looks + 3 earlier grades. Plus 57 upstream filters. |
| 转场 families | 200 | **29** `marquee.*` transitions | Family shaders, not every dir×softness combo. Plus 22 upstream. |
| 文字动画 | 200 | **70** `kind = "textanim"` | 入场 25 + 出场 12 + 循环 8 + 字幕动画 16 + 组合 9 (no speed triples). |
| 贴纸 | 472 | **11** `kind = "sticker"` + existing ShapeGrid | Parametric shapes/frames/bubbles; no JY IP assets. |
| 花字 | 322 | **220** | `marquee_huazi_ports_are_present` **ok** (青焰·描边). |
| 文字模板 | 233 | **216** | 18 layouts × 12 themes; `marquee_text_templates_are_present` **ok**. |
| 智能包装 | — | **40** project templates | `concat-host/smart-packs`; `builtin_smart_packs_are_listed` **ok**. |

Catalogue total: 448 packages (320 `marquee.*` + 128 `concat.*`).

## Wiring

- New package kinds: `sticker`, `textanim`. 贴纸 tab lists sticker packages under ShapeGrid; 文本 page has a 文字动画 row.
- 字幕 tab already runs local Whisper via `concat-speech` (`CaptionsForm` → `captions-begin` → whisper.cpp). No Jianying caption backend.
- Identifier lookups for downloaded models also try `app.marquee.editor`.

## Tests

- `cargo test -p concat-effects --lib`: **74 passed**
- `cargo test -p concat --lib marquee_`: **2 passed** (花字 220, 文字模板 216)
- `cargo test -p concat-host --lib dirs::`: **5 passed**
- `builtin_smart_packs_are_listed`: **ok** (40)

## Not done / limits

- Text-anim packages are catalogued and can be applied as visual layers; they are not yet a full title-animator (typewriter/stagger glyph timing).
- Sticker packages are parametric overlays, not hundreds of emoji glyphs.
- Transition/effect combinatorial JY SKUs (every direction × softness × amount) were ported as families with sliders.
- Android/iOS bundle IDs unchanged. README translations still mention upstream Flatpark `app.concat.editor` URLs.
- Nothing force-pushed; binary not shipped.
