# 幕次-on-concat milestone 1

Recorded Asia/Tokyo, Sunday 8 Nov 2026 around 02:40.

The editor binary runs as `marquee` against FFmpeg 8.1 headers and libraries
vendored at `vendor/ffmpeg` (BtbN n8.1.3 linux64 lgpl-shared). Launch:

```
CONCAT_GPU=software DISPLAY=:11 marquee --project <dir>
```

`--software` and `--project` are mutually exclusive; software drawing is
`CONCAT_GPU=software` (or a prior `--software`, which only opens the start
page). A project directory needs `concat.json` with camelCase video fields
(`rateNum`, `rateDen`).

`--version` prints `幕次 0.2.9 (fork of Concat)`. Window title is `幕次`.
Preferred size is 2560×1320; on this 1920×1200 screen it maximises to
1920×1159. No Vulkan drivers: Slint falls back from wgpu to the next surface,
preview cards stay undrawn, export previews mention llvmpipe.

## Screenshots

- `marquee_start_screen.png` — Chinese start page. The binary still says
  「欢迎使用 Concat」; `locales/zh-Hans.json` and `en.json` now say 幕次
  (needs a concat UI rebuild to show). Footer already reads `幕次 0.2.9`.
- `marquee_editor_running.png` — empty project 「幕次试片」, 1920×1080 30 fps.
  JY chrome: dark surfaces, teal `#01B9C6` export, Chinese library tabs
  including 文本 / 贴纸 / 字幕 / 智能包装, rail + library + preview +
  inspector + timeline.
- `marquee_editor_text_tab.png` — same session, pointer over the 文本 tab.

## Coverage

| Item | Count / status |
| --- | --- |
| 花字 text presets `marquee.huazi.*` | 220 on disk (22 colourways × 10 treatments); `presets.rs::marquee_huazi_ports_are_present` asserts 220 and 青焰·描边. Not executed this run (concat `--lib` rebuild is memory-heavy). Total text-presets folders: 265. |
| New effect packages `marquee.*` | 7: teal-grade, cool-steel, film-contrast (filters, display WGSL), corner-falloff, glow-rim (effects), dip-black, cross-soft (transitions + shaders). |
| Upstream packages | 128 (`concat.*`); catalogue total 135. |
| `cargo test -p concat-effects --lib` | 74 passed, 0 failed (after adding `fixtures.toml` probes). |
| JY chrome tokens | title 30 / `#141414`, tabs 58 / `#2A2A2A`, surface `#222222`, accent `#01B9C6`, seat gap 7, dock ratios aimed at rail 96 / library 710 / preview 1248 / inspector 474 / timeline 558 on a 2560×1320 frame. |
| Default locale | `zh-Hans` |
| FFmpeg | 8.1.3 dev + shared libs via `FFMPEG_DIR` |
| Binary | `src/target/debug/marquee` (local only, not shipped) |

## Not in this milestone

Sticker kind, richer 文字模板 / 文字动画, 智能包装 as project templates,
Whisper caption wiring beyond existing concat-speech, pixel-perfect JY
parity, remaining user-visible “Concat” strings in settings/export copy,
`app.concat.editor` identifier. `docs-eval/` left untracked. Nothing
force-pushed.
