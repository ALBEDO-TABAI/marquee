# Liquid glass audit (幕次)

Asia/Tokyo, 8 November 2026. Compared against Ready Poster Printer
(` ready-poster-printer/src/styles/glass.css`, `tokens.css`) and Apple’s
guidance that Liquid Glass belongs on *floating* surfaces over content,
not on dense reading panes.

Slint 1.18 has no `backdrop-filter`. Poster Printer’s own fallback when
blur is missing is to raise `--glass-alpha` and keep the tint / specular
rim / caustic / shadow stack. 幕次 does the same, and now also captures
the window’s last composed frame (`Window::take_snapshot` →
`host::capture_window_frost`) whenever a popup, tooltip, toast or modal
opens, so menus sit on a real blurred, saturated backdrop.

## How glass is drawn

`ui/primitives/glass.slint` (`Glass` + `GlassKind`):

1. Optional `frost` image — a downscaled (~80 px), box-blurred, 1.85×
   saturated copy of whatever is underneath. The preview transport uses
   `host::frost_from_image` on the last monitor frame (`Editor.preview-frost`).
   If `Image::to_rgba8` fails, `MonitorPane` frosts a CPU copy of the last
   `Picture::Pixels` frame instead. Popups and modal scrims use
   `GlassChrome.frost`, filled by `GlassChrome.refresh` →
   `host::capture_window_frost` just before the surface is shown.
   `Glass` itself prefers a locally passed frost and falls back to
   `GlassChrome.frost`.
2. Translucent wash: `Theme.glass` / `glass-strong` / `glass-clear`
   (Poster Printer alphas 0.52 / 0.62 / 0.30 on the theme’s glass tint).
3. Top-edge caustic (`Theme.glass-caustic`).
4. 1 px specular highlight (`Theme.glass-inner-hi`).
5. Host hairline `Theme.glass-edge` and drop shadow
   (`Theme.glass-shadow`, blur 24 / offset-y 8).

Window-region blur for menus and modal scrims **is** implemented via
`take_snapshot` on the software renderer (the path 幕次 falls back to
when there is no GPU). The snapshot is taken before the popup paints,
then frosted and stored on the `GlassChrome` global.

## Surface list

| Surface | Treatment | Why |
|---|---|---|
| Preview transport (play, step, timecode, ratio, quality, fit) | **Glass, transport + light frost** | One capsule, sized to its controls and centred on the picture. `glass-transport` (about 0.84 dark / 0.94 light) so time and icons stay legible; frost at 0.42 so a black frame does not average into a grey bar. Controls inside are bare until hovered. Narrow previews stack time and view controls on a second row of the same capsule. |
| Preview zoom / ratio chips | **Glass** (they live on that transport; ratio list is a glass popup) | Overlay / popover over content. |
| Preview stage / well | **Solid** (`Theme.well` / `Theme.stage`) | The picture itself; glass would veil it. |
| Title bar | **Glass-strong** wash | Chrome strip over the page. No frost (nothing pictorial behind it). |
| Timeline toolbar (`TimelineTray`) | **Glass-strong** bar; add-track menu is glass | Floats above the lanes. |
| Timeline tracks, clip bodies, ruler, playhead | **Solid** | Dense reading surface; clip colours are content. |
| Track headers | **Solid** | Part of the lane column, not an overlay. |
| Library grid, all shelves, media cards | **Solid** | Dense catalog; Apple/PP keep these opaque. |
| Library search field | **Glass** (`SearchField` idle fill) | Floating field on the shelf header. |
| Inspector body (基础 / 蒙版 / 调节 / 动画 / 变速 / 增强, text, audio) | **Solid** | Long forms; translucency would fight labels and sliders. |
| Inspector header (`PanelHeader`) | **Glass** wash | The one inspector piece that reads as a floating cap. |
| Segmented tabs inside inspector / library | **Solid** | Nested in a dense panel. |
| Context menus | **Glass** | Overlay. |
| Select / dropdown lists (including font picker, preview ratio) | **Glass** | Overlay. |
| Tooltips (window `TooltipLayer` and inspector `?` popover) | **Glass** | Overlay. |
| Toasts | **Glass** | Overlay. |
| Modal dialogs (settings, confirm, captions, speech, project, relink, new-voice, voiceover card) | **Glass-strong** sheet over a frosted + `Theme.overlay` scrim (phone `fill` sheets stay solid `Theme.panel`) | Overlay. |
| Export dialog | **Floating glass-strong card** on a desk (same recipe as Settings); full-window solid sheet on a phone / width < 600px | Overlay. |
| Welcome / start cards (empty-projects, learn side columns) | **Glass-strong** | Cards on the launch page. Primary Create tile stays solid accent. |
| Welcome page ground | **Solid** `launch-page` | The room the cards sit on. |
| Search fields (library, font picker, …) | **Glass** idle | See above. |
| Scrollbars, sliders, checkboxes, switches | **Solid** tokens (`Theme.field*`, `Theme.accent`) | Controls inside dense panes; glass would blur the value. |
| Export dialog preview checker | **Solid** `Theme.checker-a/b` | Content pattern, not chrome. |

## Tokens (both palettes)

See `theme/dark.slint` and `theme/light.slint`: `glass`, `glass-strong`,
`glass-clear`, `glass-edge`, `glass-inner-hi`, `glass-caustic`,
`glass-shadow`, plus `Theme.glass-shadow-blur` / `glass-shadow-y`.
