# Ready restyle consistency checklist

Pass = the control reads from `Theme` (or `Glass` / `GlassChrome`, which
read Theme) and looks correct in both dark and light. Visited in
`docs/design/ready-restyle-v3/{dark,light}/` unless a note says otherwise.

## Screens and chrome

| Item | Dark | Light | Notes |
|---|---|---|---|
| Welcome / launch | pass | pass | Glass-strong cards; Create stays Print. |
| Title bar | pass | pass | `Theme.glass-strong`. |
| Library: 素材 | pass | pass | Solid shelf (audit). |
| Library: 音频 | pass | pass | Solid shelf. |
| Library: 文本 | pass | pass | Solid shelf. |
| Library: 贴纸 | pass | pass | Solid shelf. |
| Library: 转场 | pass | pass | Solid shelf. |
| Library: 特效 | pass | pass | Solid shelf. |
| Library: 滤镜 | pass | pass | Solid shelf. |
| Library: 调节 | pass | pass | Solid shelf. |
| Library: 字幕 | pass | pass | Solid shelf. |
| Library: 智能包装 | pass | pass | Solid preset cards. |
| Preview stage | pass | pass | Black stage in both themes (intentional). |
| Preview transport (over video) | pass | pass | Clear glass; frost from the preview frame or `GlassChrome`. |
| Inspector 基础 | pass | pass | Solid body; header glass. |
| Inspector 蒙版 | pass | pass | Opened via `inspector-jump-section=Mask`. |
| Inspector 调节 | pass | pass | `Adjust`. |
| Inspector 动画 | pass | pass | `Animation`. |
| Inspector 变速 | pass | pass | `Speed`. |
| Inspector 增强 | pass | pass | `Enhance`. |
| Text inspector | pass | pass | First text clip selected (`c31` on tokyo-day). |
| Audio inspector | pass | pass | `jump-tab=Audio`. |
| Sticker inspector | pass | pass | First sticker-named / image clip (`sticker-gold-dot`). |
| Effect inspector | pass | pass | Same visual clip when it is also a layer; 图层 / 特效 shell. |
| Timeline tray | pass | pass | Glass-strong. |
| Timeline track headers | pass | pass | Solid. |
| Timeline clips per kind | pass | pass | Kind colours live in both palettes. |
| Playhead / ruler | pass | pass | Playhead follows Print (or the chosen accent). |
| Selection outline | pass | pass | `Theme.accent`. |
| Export dialog | pass | pass | Floating glass card + frosted scrim (desk); full sheet under 600px / phone. |
| Settings > Appearance | pass | pass | Glass modal + frosted scrim; 深色 / 光 switch verified. |
| Captions form | pass | pass | `CaptionsMsg::Open` / same `Modal` shell. |
| Smart pack / preset cards | pass | pass | Library tab 6 photographed. |
| Empty states | pass | pass | Welcome empty-projects is glass. |
| Context menu | pass | pass | File menu via `menu_bar_token`; `GlassChrome` frost behind the popup. |
| Dropdown / select | pass | pass | Preview quality list summoned; frost captured before `show()`. |
| Tooltip | pass | pass | Glass bubble (`Tips`). |
| Toast | pass | pass | Glass pill, bottom-right (“Project saved”). |
| Search field | pass | pass | Glass idle fill. |
| Segmented control | pass | pass | Solid well + field. |
| Slider / knob / stepper | pass | pass | Theme field tokens. |
| Checkbox / switch | pass | pass | Theme accent. |
| Scrollbar | pass | pass | Theme field / accent. |
| Text field | pass | pass | Theme field + accent focus. |
| Dialog buttons | pass | pass | `Button` in `modal.slint`. |

## How overlays get real blur

Slint has no `backdrop-filter`. `GlassChrome.refresh` asks Rust for
`Window::take_snapshot`, then `frost_rgba` (downscale ~80px, box-blur
twice, saturate 1.85×). Menus, selects, tooltips, toasts and modal /
export scrims read that image. Preview transport still prefers a frost
built from the decoded frame; if `Image::to_rgba8` fails it falls back
to the last CPU `Picture::Pixels` copy.

## Hard-coded colours left on purpose

These are **not** chrome and were left as literals:

- Title swatches (`Theme.swatches`), canvas colour presets, phone colour
  chips, avatar palette — they *are* the colours on offer.
- Colour-picker / grading wheels and hue ramps — they depict the spectrum.
- Channel identity in grading (R/G/B).
- `#808080` custom-accent placeholder in `theme.slint`.
- Cutting-stroke preview (`#ff5a5a99` when erasing) — tool ink on the
  picture, not window chrome.
- Modal progress shimmer gradient (white alphas).

## Light mode

`Theme.dark` defaults to `true`. Settings > Appearance switches it
(prefs key `dark`). Light `fg-dim` `#5f5f66` and dark `fg-dim` `#8e8e94`
meet WCAG AA against `panel` / `well`. Clip-ink stays white on kind
marks. Stage stays black in both themes.

## Still not a pixel-perfect match

- The phone editor layout was retokened but not photographed this round.
- Preview is often black at `00:00:00` on this project, so transport frost
  has little picture to pick up until a later frame is shown.
- Title-bar File menu is the context-menu photograph (same `ContextMenu`
  primitive as a clip menu). Clip menus still need a right-click to set
  `asked` on the lanes that own them.
- On tokyo-day, `sticker-gold-dot` is also the first layer-like clip, so
  the sticker and effect inspector frames can show the same selection.
- `CONCAT_SHOT_PORT` exists only as a local screenshot driver; it is off
  unless the environment variable is set.
