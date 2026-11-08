#!/usr/bin/env python3
"""Drive 幕次 via CONCAT_SHOT_PORT and photograph every Ready restyle surface."""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 17421
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(
    "docs/design/ready-restyle-v3"
)
FFMPEG = Path("vendor/ffmpeg/bin/ffmpeg")
DISPLAY = ":11.0"
SIZE = "1920x1200"

LIBRARY = [
    ("lib-media", {"op": "library", "tab": 0, "text_category": 0}),
    ("lib-audio", {"op": "library", "tab": 8, "text_category": 0}),
    ("lib-text", {"op": "library", "tab": 1, "text_category": 0}),
    ("lib-stickers", {"op": "library", "tab": 2, "text_category": 0}),
    ("lib-transitions", {"op": "library", "tab": 3, "text_category": 0}),
    ("lib-effects", {"op": "library", "tab": 4, "text_category": 0}),
    ("lib-filters", {"op": "library", "tab": 5, "text_category": 0}),
    ("lib-adjustments", {"op": "library", "tab": 7, "text_category": 0}),
    ("lib-captions", {"op": "library", "tab": 1, "text_category": 2}),
    ("lib-smart-pack", {"op": "library", "tab": 6, "text_category": 0}),
]

INSPECTOR = [
    ("insp-video-basic", "video", "Video", ""),
    ("insp-video-mask", "video", "Video", "Mask"),
    ("insp-video-adjust", "video", "Video", "Adjust"),
    ("insp-video-anim", "video", "Video", "Animation"),
    ("insp-video-speed", "video", "Video", "Speed"),
    ("insp-video-enhance", "video", "Video", "Enhance"),
    ("insp-text", "text", "Video", ""),
    ("insp-audio", "audio", "Audio", "AudioEffects"),
    ("insp-sticker", "sticker", "Video", ""),
    ("insp-effect", "effect", "Effects", ""),
]


def cmd(op: dict, timeout: float = 8.0) -> str:
    raw = json.dumps(op, ensure_ascii=False) + "\n"
    with socket.create_connection(("127.0.0.1", PORT), timeout=timeout) as sock:
        sock.sendall(raw.encode())
        sock.shutdown(socket.SHUT_WR)
        data = b""
        sock.settimeout(timeout)
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            data += chunk
            if b"\n" in data:
                break
    reply = data.decode(errors="replace").strip()
    print(f"  shot {op.get('op')}: {reply}", flush=True)
    return reply


def wait_ping(seconds: float = 90.0) -> None:
    deadline = time.time() + seconds
    last = ""
    while time.time() < deadline:
        try:
            last = cmd({"op": "ping"}, timeout=2.0)
            if last.startswith("ok"):
                return
        except OSError as error:
            last = str(error)
            time.sleep(0.6)
    raise SystemExit(f"shot port not ready: {last}")


def grab(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp.png")
    subprocess.run(
        [
            str(FFMPEG),
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-f",
            "x11grab",
            "-video_size",
            SIZE,
            "-i",
            DISPLAY,
            "-vframes",
            "1",
            str(tmp),
        ],
        check=True,
    )
    tmp.replace(path)
    print(f"  wrote {path} ({path.stat().st_size} bytes)", flush=True)


def settle(seconds: float = 0.45) -> None:
    time.sleep(seconds)


def photograph_theme(theme: str, dark: bool) -> list[str]:
    dest = OUT / theme
    dest.mkdir(parents=True, exist_ok=True)
    names: list[str] = []

    def shot(name: str, wait: float = 0.5) -> None:
        settle(wait)
        grab(dest / f"{name}.png")
        names.append(name)

    cmd({"op": "close"})
    cmd({"op": "theme", "dark": dark})
    settle(0.4)

    cmd({"op": "library", "tab": 0, "text_category": 0})
    shot("editor-full", 0.6)
    grab(dest / "titlebar.png")  # same frame; contact sheet uses a crop later
    names.append("titlebar")

    for name, op in LIBRARY:
        cmd({"op": "close"})
        cmd(op)
        shot(name, 0.45)

    for name, kind, jump_tab, section in INSPECTOR:
        cmd({"op": "close"})
        sel = cmd({"op": "select_clip", "kind": kind})
        if sel.startswith("ok"):
            cmd({"op": "inspector", "jump_tab": jump_tab, "jump_section": section})
        shot(name, 0.5)

    cmd({"op": "close"})
    cmd({"op": "settings", "tab": 1})
    shot("settings-appearance", 0.55)

    cmd({"op": "close"})
    cap = cmd({"op": "captions"})
    shot("captions", 0.55)

    cmd({"op": "close"})
    cmd({"op": "menu", "index": 0})
    shot("context-menu", 0.45)

    cmd({"op": "close"})
    cmd({"op": "dropdown"})
    shot("dropdown", 0.45)

    cmd({"op": "close"})
    cmd({"op": "tooltip", "text": "Play"})
    shot("tooltip", 0.35)

    cmd({"op": "close"})
    cmd({"op": "toast", "message": "Project saved", "failed": False})
    shot("toast", 0.35)
    # Confirmations hold 3.5s; wait them out so later overlays are clean.
    settle(3.6)

    cmd({"op": "close"})
    cmd({"op": "export"})
    shot("export", 0.6)

    cmd({"op": "close"})
    cmd({"op": "welcome"})
    shot("welcome-full", 0.7)

    # Re-open is not available over the shot port; the runner relaunches
    # per theme when welcome must not precede the editor shots.
    return names


def contact_sheet(theme: str, names: list[str]) -> None:
    from PIL import Image, ImageDraw, ImageFont

    folder = OUT / theme
    # unique preserve order
    seen = []
    for name in names:
        if name not in seen and (folder / f"{name}.png").exists():
            seen.append(name)
    if not seen:
        return
    cols = 4
    thumb_w, thumb_h = 460, 270
    pad, label_h = 16, 28
    rows = (len(seen) + cols - 1) // cols
    sheet = Image.new(
        "RGB",
        (cols * (thumb_w + pad) + pad, rows * (thumb_h + label_h + pad) + pad + 36),
        (18, 18, 20) if theme == "dark" else (235, 235, 238),
    )
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16
        )
        title_font = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22
        )
    except OSError:
        font = ImageFont.load_default()
        title_font = font
    ink = (250, 250, 252) if theme == "dark" else (28, 28, 32)
    draw.text((pad, 10), f"Ready restyle v3 — {theme}", fill=ink, font=title_font)
    for i, name in enumerate(seen):
        im = Image.open(folder / f"{name}.png").convert("RGB")
        im.thumbnail((thumb_w, thumb_h))
        cell = Image.new("RGB", (thumb_w, thumb_h), (0, 0, 0))
        cell.paste(im, ((thumb_w - im.width) // 2, (thumb_h - im.height) // 2))
        r, c = divmod(i, cols)
        x = pad + c * (thumb_w + pad)
        y = 46 + r * (thumb_h + label_h + pad)
        sheet.paste(cell, (x, y))
        draw.text((x, y + thumb_h + 4), name, fill=ink, font=font)
    dest = OUT / f"{theme}_sheet.png"
    sheet.save(dest)
    print(f"sheet {dest} ({dest.stat().st_size} bytes)", flush=True)


def main() -> None:
    theme = sys.argv[3] if len(sys.argv) > 3 else "dark"
    dark = theme != "light"
    print(f"photographing {theme} via port {PORT}", flush=True)
    wait_ping()
    names = photograph_theme(theme, dark)
    contact_sheet(theme, names)


if __name__ == "__main__":
    main()
