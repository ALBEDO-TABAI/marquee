# M8 re-render of 小制片 tokyo-day

Source project (read-only): `tester-projects/projects/tokyo-day/`
Output: `tokyo-day.mp4` (78.000 s, 1920×1080 @ 30)

## Visual
- `title-t2.png` / `export-t2.png` at t=2s: 花字 reads **午前的光** (the last glyph is no longer missing). Window-frame RGB fringe is greatly reduced versus `marquee-test/screenshots/film-02-title.png`.
- `dusk-t48.png`: preview at 48s.

## Loudness (ffmpeg ebur128=peak=true)
| file | Integrated | True peak |
| --- | --- | --- |
| original `tester-projects/out/tokyo-day.mp4` | −22.8 LUFS | −4.4 dBFS |
| this re-export (normalize default on) | −15.0 LUFS | −0.9 dBFS |

Target was −14 LUFS and ≤ −1 dBTP. Single-pass `loudnorm=I=-14:TP=-1.0:LRA=11:linear=true` landed 1 LU quiet and 0.1 dB over the true-peak cap.

## Chinese ASR (`captions.transcribe`, language=zh → model `small` + default prompt)
See `zh-transcribe.json`. Roughly correct paragraph with punctuation; substitutions include 轻→清, 漏进→露进, 像→向, 电线杆→电线干, 绣球→嗅求. Model file: `$XDG_DATA_HOME/app.marquee.editor/whisper-models/ggml-small.bin` (~466 MiB, not committed).

Duck keys in their saved project were already written (3 keys) before this fix; re-export does not rewrite them. Re-apply `duckAudio` to get 4 keys.
