# The local music and sound-effect library

The Audio page's sidebar has, under 声音 (Mine, Favourites, Recently used),
two shelves laid out the way Jianying lays out its own: **音乐库 / Music**
and **音效库 / Sound effects**, one row per category. Their rows show a
cover, the title, the artist (or an effect's tag) and the length, a star and
a plus. A click plays the sound in the source preview, the plus lays it at
the playhead on the first lane with room, a drag lays it where it is
dropped, and the star keeps it on Favourites. A sound laid down goes to the
head of Recently used. The search box over a shelf searches the whole shelf
by title, artist and tag; matches in the title come first.

The shelves read a **folder on this machine**. Nothing in it is shipped or
downloaded by the app, and nothing in it belongs in this repository - a
catalogue of commercial music is licensed to whoever fetched it, not to
everyone who clones Marquee. `.gitignore` refuses any `audio-library/`
folder.

## Where the folder is

1. `MARQUEE_AUDIO_LIBRARY`, when it is set, or
2. `<data>/audio-library`, where `<data>` is the app's data folder
   (`~/Library/Application Support/app.marquee.editor` on macOS).

A symlink works. Favourites and Recently used are kept apart from the
library, in `<config>/audio-mine.json`, by card id (`music-<id>`,
`sfx-<id>`).

## The manifest

`manifest.json` at the folder's root:

```json
{
  "schema": "marquee.audio-library/1",
  "music": {
    "categories": [
      { "id": "6678556627852856076", "name": "推荐音乐", "items": ["7274049030760925238"] }
    ],
    "items": {
      "7274049030760925238": {
        "id": "7274049030760925238",
        "title": "Drink Shop",
        "artist": "Aleksandar Kiprov",
        "duration": 130,
        "audio": "music/7274049030760925238.mp3",
        "cover": "covers/music-1f0c….jpg",
        "beats": "beats/7274049030760925238.json",
        "tags": ["嘻哈/说唱"],
        "vip": true
      }
    }
  },
  "sfx": { "categories": [], "items": {} }
}
```

- `duration` is in seconds.
- `audio`, `cover` and `beats` are relative to the folder; a path that
  leaves it (`..`, absolute) is ignored. An entry whose `audio` file is not
  there is listed but cannot be played or laid down.
- `cover` must be PNG or JPEG.
- `beats` is a JSON object with a `time` (or any `…time…`) list of beat
  times, in milliseconds or seconds.
- An id a category lists that `items` does not have is dropped.

## Making one from your own files

`scripts/audio_library.py` builds a manifest from folders of sound files you
have the right to use - one sub-folder per category:

```
my-sounds/
  music/<category>/*.mp3|m4a|wav|flac|ogg
  sfx/<category>/*.mp3|wav|…
```

```
python3 scripts/audio_library.py my-sounds          # writes my-sounds/manifest.json
MARQUEE_AUDIO_LIBRARY=$PWD/my-sounds cargo dev
```

It reads lengths with `ffprobe` when it is on the PATH, and takes a
`cover.png`/`cover.jpg` beside a file of the same stem, or in its category
folder, as the cover.
