#!/usr/bin/env python3
"""Build a marquee.audio-library/1 manifest from folders of sound files.

    scripts/audio_library.py <folder>

<folder>/music/<category>/<files> and <folder>/sfx/<category>/<files>; the
manifest is written to <folder>/manifest.json. See docs/AUDIO_LIBRARY_LOCAL.md.
Only for sounds you may use: the folder stays out of the repository.
"""
import hashlib
import json
import pathlib
import shutil
import subprocess
import sys

EXTENSIONS = {".mp3", ".m4a", ".aac", ".wav", ".flac", ".ogg", ".opus", ".aif", ".aiff"}
COVERS = (".png", ".jpg", ".jpeg")


def duration(path):
    if not shutil.which("ffprobe"):
        return 0.0
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True,
    ).stdout.strip()
    try:
        return round(float(out), 3)
    except ValueError:
        return 0.0


def cover(path, category):
    for folder, stem in ((path.parent, path.stem), (category, "cover")):
        for ext in COVERS:
            candidate = folder / (stem + ext)
            if candidate.is_file():
                return candidate
    return None


def shelf(root, name):
    out = {"categories": [], "items": {}}
    base = root / name
    if not base.is_dir():
        return out
    for category in sorted(p for p in base.iterdir() if p.is_dir()):
        ids = []
        for path in sorted(category.iterdir()):
            if path.suffix.lower() not in EXTENSIONS:
                continue
            rel = path.relative_to(root).as_posix()
            item_id = hashlib.sha1(rel.encode()).hexdigest()[:16]
            art = cover(path, category)
            out["items"][item_id] = {
                "id": item_id,
                "title": path.stem,
                "artist": "",
                "duration": duration(path),
                "audio": rel,
                "cover": art.relative_to(root).as_posix() if art else None,
                "tags": [category.name],
            }
            ids.append(item_id)
        out["categories"].append({"id": category.name, "name": category.name, "items": ids})
    return out


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    root = pathlib.Path(sys.argv[1]).resolve()
    manifest = {"schema": "marquee.audio-library/1", "music": shelf(root, "music"), "sfx": shelf(root, "sfx")}
    (root / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    for key in ("music", "sfx"):
        print(f"{key}: {len(manifest[key]['categories'])} categories, {len(manifest[key]['items'])} sounds")


if __name__ == "__main__":
    main()
