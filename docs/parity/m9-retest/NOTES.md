# M9 retest — round-2 N1–N7

Recorded Asia/Tokyo, 8 Nov 2026. Engine: `concat-cli` rebuilt after the M9 patches. `CONCAT_GPU=software`. Tester projects were opened read-only from `tester-projects/round2/projects/` (that tree was not modified).

## Exports

| Film | Output | Duration | Frames | Wall | Effective fps | Size |
| --- | --- | --- | --- | --- | --- | --- |
| tokyo-day-3min | `tokyo-day-3min.mp4` | 180.004 s | 5400 @ 1080p30 | **231.57 s** | **23.3 fps** | 190 MiB |
| tokyo-day-verify (78 s) | `tokyo-day-verify.mp4` | 78.004 s | 2340 @ 1080p30 | **106.80 s** | **21.9 fps** | 79 MiB |

Export spec matched the tester: `width=1920`, `height=1080`, `rateNum=30`, `crf=20`, `preset=veryfast`, default `normalize`. Round-2 baselines were 225.3 s (~24 fps) and 109.6 s (~21 fps). Two-pass loudnorm adds a measure+apply pass on the mixed soundtrack (~a few seconds). Raising `IN_FLIGHT` from 2 to 6 *slowed* the 3-minute film to 300.1 s (~18 fps) on llvmpipe; the overlap was left at 2.

## Loudness (ffmpeg `ebur128=peak=true` on the muxed files)

| Film | Integrated | LRA | True peak | Target |
| --- | --- | --- | --- | --- |
| tokyo-day-3min | **−14.4 LUFS** | 24.5 LU | **−1.2 dBTP** | −14 ±0.5 LUFS, TP ≤ −1.0 |
| tokyo-day-verify | **−14.4 LUFS** | 21.8 LU | **−1.4 dBTP** | same |

Round-2 (single-pass loudnorm) was −14.9 / −0.9 (3 min) and −15.0 / −1.0 (78 s). The two-pass measure→linear path plus an `alimiter` ceiling of −1.5 dBTP (headroom for AAC true-peak overshoot) lands I inside the window and TP under −1.0 on both films.

A first M9 pass that limited at −1.0 dBTP hit I = −14.3 on both files but the 3-minute muxed AAC true-peaked at **−0.8 dBTP**; that filter pair was tightened before these files were written.

## Per-issue

| ID | Status | Notes |
| --- | --- | --- |
| N1 | fixed | `mask*` keys now enable `ClipMask::of(MaskShape::Rectangle)`. Test: `mask_keys_enable_a_default_mask`. |
| N2 | fixed | Two-pass `loudnorm` (`measured_*` + `linear=true`) then `alimiter` at −1.5 dBTP. Measured above. |
| N3 | fixed | `copyClips`/`pasteClips`/`duplicateClips` (aliases `copyClip`, `pasteClip`, `duplicateClip`), multi-select via `clipIds`/`clipId`. Copy is not an undo step; paste and duplicate are. Test: `copy_paste_and_duplicate_clips_round_trip_with_undo`. |
| N4 | fixed | `marquee.grain*` / `blocknoise*` / `scanlines*` rewritten as monochrome luma treatments (they shared an RGB-split template). Intentional chromatic families left alone. Static audit: `marquee_shaders_do_not_hide_rgb_split_behind_the_wrong_name`. GPU grey+edge card: `grain_on_a_gray_card_does_not_fringe` (grain45 max chroma ≤ 6; `rgbsplit45` control ≥ 12). |
| N5 | fixed | Sticker `addLayerClip` default scale **0.20** (was 0.30). Test: `a_sticker_layer_defaults_to_a_small_scale`. |
| N6 | fixed | All 42 smart-packs: no `marquee.ch01` cyan slab; cream/ink/rust titles; smaller captions on translucent black; JY-sized stickers (0.18–0.22) in corners; restrained grain FX. Tests: `sticker_layers_are_not_full_frame`. |
| N7 | fixed | `xdg_data_home` treats only an *absolute* `XDG_DATA_HOME` as a base; otherwise `~/.local/share`. Default model dir documented as `~/.local/share/app.marquee.editor/whisper-models/`. Test: `linux_default_data_dir_is_local_share_app_id`. |
| zh homophones | fixed | `captions.transcribe` accepts `glossary: ["绣球", …]` (appended to the whisper prompt). After decode: built-in map (电线干→电线杆, 嗅求→绣球, 露进→漏进, 向有人→像有人, 得很清→得很轻) + `captions-dictionary.json` under app data/config + same-length fuzzy replace for glossary terms. Tests in `transcribe::m8_defaults`. Whisper itself was not re-run on narration.wav this round. |
| export speed | tried | See above. Software 1080p stays ~23 fps on the 3-minute cut (two-pass audio included). `IN_FLIGHT=6` was a regression on llvmpipe and was not kept. |

The large `.mp4` files are left untracked (same policy as m8-retest).
