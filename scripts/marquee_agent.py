#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Headless driver for 幕次 (concat-cli api).

Keep one process open for the whole session so projects stay loaded.
See docs/AGENT-GUIDE.md.

  python3 scripts/marquee_agent.py smoke
  python3 scripts/marquee_agent.py stress
  python3 scripts/marquee_agent.py sku
  python3 scripts/marquee_agent.py audio
  python3 scripts/marquee_agent.py presets
  python3 scripts/marquee_agent.py captions
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "src/target/debug/concat-cli"
FFMPEG = ROOT / "vendor/ffmpeg/bin/ffmpeg"
PRESETS = ROOT / "src/crates/concat/text-presets"
ENV_FILE = Path("/tmp/marquee-build.env")
M5 = ROOT / "docs/parity/m5-demo"
M6 = ROOT / "docs/parity/m6-demo"
M7 = ROOT / "docs/parity/m7-demo"


def load_build_env() -> dict[str, str]:
    env = os.environ.copy()
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            if line.startswith("export "):
                key, value = line[len("export ") :].split("=", 1)
                env[key] = value.strip().strip('"')
    env["CONCAT_GPU"] = "software"
    env.setdefault("DISPLAY", ":11")
    return env


def rss_kb(pid: int) -> int:
    try:
        for line in Path(f"/proc/{pid}/status").read_text().splitlines():
            if line.startswith("VmRSS:"):
                return int(line.split()[1])
    except (FileNotFoundError, ValueError, IndexError):
        return 0
    return 0


class Sampler:
    def __init__(self, pid: int) -> None:
        self.pid = pid
        self.peak = 0
        self.samples = 0
        self._stop = threading.Event()
        self._thr = threading.Thread(target=self._run, daemon=True)

    def start(self) -> None:
        self._thr.start()

    def stop(self) -> int:
        self._stop.set()
        self._thr.join(timeout=2)
        return self.peak

    def _run(self) -> None:
        while not self._stop.is_set():
            now = rss_kb(self.pid)
            if now > self.peak:
                self.peak = now
            self.samples += 1
            self._stop.wait(0.4)


class Session:
    def __init__(self) -> None:
        if not CLI.is_file():
            raise SystemExit(f"missing {CLI}; build concat-cli first")
        self.env = load_build_env()
        self.proc = subprocess.Popen(
            [str(CLI), "api"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
            env=self.env,
        )
        self.events: list[dict] = []
        self.stderr_tail: list[str] = []
        threading.Thread(target=self._drain_err, daemon=True).start()

    def _drain_err(self) -> None:
        assert self.proc.stderr is not None
        for line in self.proc.stderr:
            self.stderr_tail.append(line.rstrip())
            if len(self.stderr_tail) > 200:
                self.stderr_tail = self.stderr_tail[-200:]

    def close(self) -> None:
        if self.proc.poll() is None:
            try:
                self.proc.stdin.close()
            except Exception:
                pass
            self.proc.terminate()
            try:
                self.proc.wait(timeout=8)
            except subprocess.TimeoutExpired:
                self.proc.kill()

    def _read(self, accept_events: bool = False) -> dict:
        assert self.proc.stdout is not None
        while True:
            line = self.proc.stdout.readline()
            if not line:
                raise RuntimeError(
                    "concat-cli closed stdout\n" + "\n".join(self.stderr_tail[-20:])
                )
            obj = json.loads(line)
            if "method" in obj and "result" not in obj and "error" not in obj:
                self.events.append(obj)
                if accept_events:
                    return obj
                continue
            return obj

    def call(self, method: str, **params) -> dict:
        rec = {"method": method, **params}
        assert self.proc.stdin is not None
        self.proc.stdin.write(json.dumps(rec, ensure_ascii=False) + "\n")
        self.proc.stdin.flush()
        reply = self._read(accept_events=False)
        if "error" in reply:
            raise RuntimeError(f"{method} failed: {reply['error']}")
        # Keep empty arrays (catalogue.list kind=generator → []) instead of {}.
        if "result" in reply:
            return reply["result"]
        return {}

    def created_id(self, result: dict) -> str:
        cid = result.get("createdId")
        if not cid:
            raise RuntimeError(f"no createdId in {json.dumps(result)[:240]}")
        return cid

    def edit(self, path: str, op: str, **kw) -> dict:
        return self.call("edit.apply", path=path, command={"op": op, **kw})

    def try_edit(self, path: str, op: str, **kw) -> dict:
        try:
            return {"ok": True, "result": self.edit(path, op, **kw)}
        except RuntimeError as exc:
            return {"ok": False, "error": str(exc)}

    def export_and_wait(self, path: str, output: str, **spec) -> dict:
        ack = self.call("export.run", path=path, output=output, **spec)
        while True:
            ev = self._read(accept_events=True)
            name = ev.get("method")
            if name == "export.done":
                return ev.get("params") or {}
            if name == "export.failed":
                raise RuntimeError(f"export.failed: {ev}")
            if name == "export.progress":
                continue
            if "error" in ev:
                raise RuntimeError(f"export error: {ev['error']}")
            if "result" in ev:
                # stray reply; keep waiting
                continue


def read_preset(preset_id: str) -> dict:
    text = (PRESETS / preset_id / "preset.toml").read_text()
    style: dict = {}
    section = None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if "=" not in line:
            continue
        key, value = [p.strip() for p in line.split("=", 1)]
        if value.startswith('"') and value.endswith('"'):
            parsed: object = value[1:-1]
        elif value in ("true", "false"):
            parsed = value == "true"
        else:
            try:
                parsed = float(value) if "." in value else int(value)
            except ValueError:
                parsed = value
        if section == "style":
            style[key] = parsed
        elif key == "name":
            style.setdefault("_name", parsed)
    return style


def write_srt(path: Path, cues: list[tuple[float, float, str]]) -> None:
    def ts(sec: float) -> str:
        ms = int(round(sec * 1000))
        h, ms = divmod(ms, 3600_000)
        m, ms = divmod(ms, 60_000)
        s, ms = divmod(ms, 1000)
        return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

    chunks = []
    for i, (start, end, text) in enumerate(cues, 1):
        chunks.append(f"{i}\n{ts(start)} --> {ts(end)}\n{text}\n")
    path.write_text("\n".join(chunks), encoding="utf-8")


def make_clips(out: Path, count: int = 6) -> list[Path]:
    out.mkdir(parents=True, exist_ok=True)
    colors = [
        "0x0A3A4A",
        "0x4A2418",
        "0x1A3A22",
        "0x3A1A4A",
        "0x4A3A10",
        "0x1A2A4A",
    ]
    files = []
    ff = str(FFMPEG) if FFMPEG.is_file() else "ffmpeg"
    for i in range(count):
        dest = out / f"clip-{i:02d}.mp4"
        files.append(dest)
        if dest.exists() and dest.stat().st_size > 1000:
            continue
        color = colors[i % len(colors)]
        subprocess.run(
            [
                ff,
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-f",
                "lavfi",
                "-i",
                f"color=c={color}:s=1280x720:r=30:d=2",
                "-pix_fmt",
                "yuv420p",
                str(dest),
            ],
            check=True,
        )
    return files


def first_id(packages: list[dict], prefix: str = "marquee.") -> str:
    for pkg in packages:
        if pkg.get("id", "").startswith(prefix):
            return pkg["id"]
    if packages:
        return packages[0]["id"]
    raise RuntimeError("empty catalogue")


def build_project(session: Session, dest: Path, n_clips: int, n_cues: int, label: str) -> dict:
    dest.mkdir(parents=True, exist_ok=True)
    media_dir = dest / "media"
    clips = make_clips(media_dir)
    srt_path = dest / "captions.srt"
    cues = [
        (i * 0.28, i * 0.28 + 0.26, f"字幕 {i+1:03d} · 幕次")
        for i in range(n_cues)
    ]
    write_srt(srt_path, cues)

    name = label
    proj = dest / name
    if proj.exists():
        shutil.rmtree(proj)

    session.call(
        "project.create",
        location=str(dest),
        name=name,
        video={"width": 1280, "height": 720, "rateNum": 30, "rateDen": 1},
    )
    path = str(proj)

    media_ids = []
    for file in clips:
        result = session.call("media.import", path=path, file=str(file))
        media_ids.append(session.created_id(result))

    # Extra lanes so overlays do not pile onto V1.
    for _ in range(8):
        session.edit(path, "addTrack")

    doc = session.call("project.get", path=path)
    tracks = [t["id"] for t in doc["project"]["timelines"][0]["tracks"]]
    video_track = tracks[0]

    clip_len = 0.28
    video_ids = []
    t = 0.0
    for i in range(n_clips):
        mid = media_ids[i % len(media_ids)]
        result = session.edit(
            path, "addClip", mediaId=mid, trackId=video_track, start=t, ripple=False
        )
        cid = session.created_id(result)
        # Media is 2s; pull the tail in so the run stays compact.
        session.edit(path, "trimClip", clipId=cid, edge="end", delta=-(2.0 - clip_len))
        video_ids.append(cid)
        t += clip_len

    timeline_end = t
    effects = session.call("catalogue.list", kind="effect")
    filters = session.call("catalogue.list", kind="filter")
    transitions = session.call("catalogue.list", kind="transition")
    stickers = session.call("catalogue.list", kind="sticker")
    textanims = session.call("catalogue.list", kind="textanim")

    effect_id = first_id(effects)
    filter_id = first_id(filters)
    xf_id = first_id(transitions)
    sticker_id = first_id(stickers)
    ta_id = first_id(textanims)

    # Apply a filter + volume to the first clip, speed to the second.
    if video_ids:
        session.edit(
            path,
            "updateClip",
            clipId=video_ids[0],
            patch={
                "volume": 0.8,
                "filters": [{"id": filter_id, "enabled": True, "params": {}}],
            },
        )
    if len(video_ids) > 1:
        session.edit(path, "setClipSpeed", clipId=video_ids[1], speed=1.5, ripple=False)
    # Split a later clip and move the tail a little.
    if len(video_ids) > 8:
        target = video_ids[8]
        # clip 8 starts at 8*0.28 = 2.24, length 0.28 → split at 2.36
        session.edit(path, "splitClips", clipIds=[target], time=2.36)
        doc = session.call("project.get", path=path)
        all_ids = [c["id"] for c in doc["project"]["timelines"][0]["clips"]]
        tails = [i for i in all_ids if i not in video_ids]
        if tails:
            session.edit(
                path,
                "moveClips",
                moves=[{"clipId": tails[0], "start": 2.50, "trackId": video_track}],
            )
    session.call("edit.undo", path=path)
    session.call("edit.redo", path=path)

    if video_ids:
        session.edit(
            path,
            "setClipKey",
            clipId=video_ids[0],
            property="opacity",
            at=0.0,
            value=0.2,
        )
        session.edit(
            path,
            "setClipKey",
            clipId=video_ids[0],
            property="opacity",
            at=1.0,
            value=1.0,
        )

    huazi = read_preset("marquee.huazi.coral-outline")
    huazi["content"] = "幕次 · 珊瑚"
    session.edit(
        path,
        "addTextClip",
        start=0.0,
        duration=min(4.0, timeline_end),
        above=True,
        offsetY=-0.28,
        style={k: v for k, v in huazi.items() if not str(k).startswith("_")},
    )

    plate = read_preset("marquee.tt.name-hot")
    plate["content"] = "口播 · 人名条"
    session.edit(
        path,
        "addTextClip",
        start=0.4,
        duration=2.2,
        above=True,
        offsetY=0.34,
        style={k: v for k, v in plate.items() if not str(k).startswith("_")},
    )

    hook = read_preset("marquee.tt.hook-hot")
    hook["content"] = "金句压测"
    text = session.edit(
        path,
        "addTextClip",
        start=1.0,
        duration=2.4,
        above=True,
        offsetY=-0.08,
        style={k: v for k, v in hook.items() if not str(k).startswith("_")},
    )
    text_id = session.created_id(text)
    session.edit(
        path,
        "updateClip",
        clipId=text_id,
        patch={"videoEffects": [{"id": ta_id, "enabled": True, "params": {}}]},
    )

    session.edit(
        path,
        "addLayerClip",
        start=0.0,
        duration=min(5.0, timeline_end),
        effectId=sticker_id,
        name="贴纸",
    )
    session.edit(
        path,
        "addLayerClip",
        start=0.0,
        duration=min(timeline_end, 8.0),
        effectId=effect_id,
        name="特效",
    )
    # Transition over the first cut (~0.28s is too tight; sit near clip 5/6).
    session.edit(
        path,
        "addTransitionClip",
        start=max(0.1, 5 * clip_len - 0.4),
        duration=0.8,
        transitionId=xf_id,
        name="转场",
    )

    # Long SRT → titles (same command the 字幕 importer uses).
    for start, end, words in cues:
        session.edit(
            path,
            "addTextClip",
            start=start,
            duration=max(0.08, end - start),
            above=True,
            offsetY=0.38,
            style={
                "content": words,
                "fontFamily": "Noto Sans CJK SC",
                "fontSize": 0.038,
                "fontWeight": 600,
                "color": "#FFFFFF",
                "strokeWidth": 0.002,
                "strokeColor": "#111111",
                "align": "center",
                "background": "#00000099",
                "backgroundPaddingX": 0.016,
                "backgroundPaddingY": 0.01,
            },
        )

    session.call("project.save", path=path)
    doc = session.call("project.get", path=path)
    n_timeline = len(doc["project"]["timelines"][0]["clips"])
    n_tracks = len(doc["project"]["timelines"][0]["tracks"])
    return {
        "path": path,
        "clips": n_timeline,
        "tracks": n_tracks,
        "media": len(media_ids),
        "duration": timeline_end,
        "effect": effect_id,
        "filter": filter_id,
        "transition": xf_id,
        "sticker": sticker_id,
        "textanim": ta_id,
        "srt": str(srt_path),
        "cues": n_cues,
    }


def run_phase(kind: str) -> dict:
    dest = M5 / kind
    dest.mkdir(parents=True, exist_ok=True)
    n_clips = 12 if kind == "smoke" else 120
    n_cues = 12 if kind == "smoke" else 90
    out = dest / f"m5-{kind}.mp4"
    report = {
        "phase": kind,
        "ok": False,
        "error": None,
    }
    session = Session()
    sampler = Sampler(session.proc.pid)
    sampler.start()
    t0 = time.perf_counter()
    try:
        built = build_project(session, dest, n_clips=n_clips, n_cues=n_cues, label=kind)
        t_build = time.perf_counter() - t0
        t1 = time.perf_counter()
        exported = session.export_and_wait(
            built["path"],
            str(out),
            crf=28,
            width=854,
            height=480,
            rateNum=24,
            rateDen=1,
        )
        t_export = time.perf_counter() - t1
        report.update(built)
        report.update(
            {
                "ok": True,
                "output": str(out),
                "outputBytes": out.stat().st_size if out.exists() else 0,
                "buildSeconds": round(t_build, 3),
                "exportSeconds": round(t_export, 3),
                "totalSeconds": round(time.perf_counter() - t0, 3),
                "peakRssKiB": sampler.stop(),
                "exportReply": exported,
                "cliPid": session.proc.pid,
            }
        )
    except Exception as exc:
        sampler.stop()
        report["error"] = str(exc)
        report["peakRssKiB"] = sampler.peak
        report["totalSeconds"] = round(time.perf_counter() - t0, 3)
        report["stderr"] = session.stderr_tail[-30:]
    finally:
        session.close()
    return report


def run_sku_phase() -> dict:
    """Apply every marquee.* catalogue package once, plus enough video
    clips to exceed 1000 timeline items, then export 1080p30."""
    dest = M7 / "sku"
    dest.mkdir(parents=True, exist_ok=True)
    out = dest / "m7-sku-1080p30.mp4"
    report = {"phase": "sku", "ok": False, "error": None, "failed": []}
    session = Session()
    sampler = Sampler(session.proc.pid)
    sampler.start()
    t0 = time.perf_counter()
    try:
        media_dir = dest / "media"
        files = make_clips(media_dir)
        name = "sku"
        proj = dest / name
        if proj.exists():
            shutil.rmtree(proj)
        session.call(
            "project.create",
            location=str(dest),
            name=name,
            video={"width": 1920, "height": 1080, "rateNum": 30, "rateDen": 1},
        )
        path = str(proj)
        media_ids = []
        for file in files:
            media_ids.append(session.created_id(session.call("media.import", path=path, file=str(file))))
        for _ in range(10):
            session.edit(path, "addTrack")
        doc = session.call("project.get", path=path)
        tracks = [tr["id"] for tr in doc["project"]["timelines"][0]["tracks"]]
        video_track = tracks[0]
        overlay_tracks = tracks[1:9] or tracks
        clip_len = 0.08
        n_video = 200
        for i in range(n_video):
            mid = media_ids[i % len(media_ids)]
            result = session.edit(path, "addClip", mediaId=mid, trackId=video_track, start=i * clip_len, ripple=False)
            cid = session.created_id(result)
            session.edit(path, "trimClip", clipId=cid, edge="end", delta=-(2.0 - clip_len))
        kinds = ["effect", "filter", "sticker", "textanim", "transition"]
        packages = []
        for kind in kinds:
            rows = session.call("catalogue.list", kind=kind)
            if isinstance(rows, list):
                packages.extend(rows)
            else:
                # untagged reply should already be a list; Session wraps result
                packages.extend(rows if isinstance(rows, list) else [])
        # Session.call returns result or {} — catalogue.list is a raw array.
        # If the helper dropped it, re-read via a dedicated call below.
        marquee = [pkg for pkg in packages if str(pkg.get("id", "")).startswith("marquee.")]
        # catalogue.list returns an array; Session.call does `reply.get("result") or {}`
        # which would turn an empty list into {}. A full list is truthy.
        if not marquee:
            raise RuntimeError(f"no marquee packages listed (got {type(packages)} {len(packages) if hasattr(packages,'__len__') else packages})")
        failed = []
        applied = 0
        for i, pkg in enumerate(marquee):
            pid = pkg["id"]
            kind = pkg.get("kind") or ""
            start = (i // len(overlay_tracks)) * clip_len
            track = overlay_tracks[i % len(overlay_tracks)]
            if kind == "transition":
                got = session.try_edit(path, "addTransitionClip", start=start, duration=0.4, transitionId=pid, name=pid)
            elif kind == "textanim":
                text = session.try_edit(
                    path, "addTextClip", start=start, duration=clip_len, above=True, offsetY=-0.2,
                    style={"content": "Aa", "fontFamily": "Noto Sans CJK SC", "fontSize": 0.08,
                           "fontWeight": 700, "color": "#FFFFFF", "align": "center"},
                )
                if text.get("ok"):
                    try:
                        tid = session.created_id(text["result"])
                        got = session.try_edit(
                            path, "updateClip", clipId=tid,
                            patch={"videoEffects": [{"id": pid, "enabled": True, "params": {}}]},
                        )
                    except RuntimeError as exc:
                        got = {"ok": False, "error": str(exc)}
                else:
                    got = text
            else:
                got = session.try_edit(path, "addLayerClip", start=start, duration=clip_len, effectId=pid, name=pid)
            if got.get("ok"):
                applied += 1
            else:
                failed.append({"id": pid, "kind": kind, "error": got.get("error")})
        # exercise presets.list
        presets = session.call("presets.list", category="huazi", query="珊瑚")
        preset_n = len(presets) if isinstance(presets, list) else 0
        session.call("project.save", path=path)
        doc = session.call("project.get", path=path)
        n_clips = len(doc["project"]["timelines"][0]["clips"])
        t_build = time.perf_counter() - t0
        t1 = time.perf_counter()
        exported = session.export_and_wait(
            path, str(out), crf=28, width=1920, height=1080, rateNum=30, rateDen=1, preset="veryfast",
        )
        t_export = time.perf_counter() - t1
        report.update({
            "ok": True,
            "path": path,
            "clips": n_clips,
            "marqueePackages": len(marquee),
            "applied": applied,
            "failedCount": len(failed),
            "failed": failed[:40],
            "presetsSearchHits": preset_n,
            "output": str(out),
            "outputBytes": out.stat().st_size if out.exists() else 0,
            "buildSeconds": round(t_build, 3),
            "exportSeconds": round(t_export, 3),
            "totalSeconds": round(time.perf_counter() - t0, 3),
            "peakRssKiB": sampler.stop(),
            "exportReply": exported,
            "width": 1920, "height": 1080, "fps": 30,
        })
    except Exception as exc:
        sampler.stop()
        report["error"] = str(exc)
        report["peakRssKiB"] = sampler.peak
        report["totalSeconds"] = round(time.perf_counter() - t0, 3)
        report["stderr"] = session.stderr_tail[-40:]
    finally:
        session.close()
    return report


def make_audio(out: Path) -> tuple[Path, Path]:
    out.mkdir(parents=True, exist_ok=True)
    ff = str(FFMPEG) if FFMPEG.is_file() else "ffmpeg"
    music = out / "music.wav"
    sfx = out / "sfx.wav"
    if not (music.exists() and music.stat().st_size > 100):
        subprocess.run([ff, "-y", "-hide_banner", "-loglevel", "error",
                        "-f", "lavfi", "-i", "sine=frequency=220:sample_rate=44100:duration=8",
                        "-ac", "2", str(music)], check=True)
    if not (sfx.exists() and sfx.stat().st_size > 100):
        subprocess.run([ff, "-y", "-hide_banner", "-loglevel", "error",
                        "-f", "lavfi", "-i", "sine=frequency=880:sample_rate=44100:duration=0.35",
                        "-ac", "2", str(sfx)], check=True)
    return music, sfx


def run_audio_phase() -> dict:
    dest = M6 / "audio"
    dest.mkdir(parents=True, exist_ok=True)
    out = dest / "m6-audio.mp4"
    report = {"phase": "audio", "ok": False, "error": None}
    session = Session()
    sampler = Sampler(session.proc.pid)
    sampler.start()
    t0 = time.perf_counter()
    try:
        media_dir = dest / "media"
        videos = make_clips(media_dir, count=2)
        music, sfx = make_audio(media_dir)
        name = "audio"
        proj = dest / name
        if proj.exists():
            shutil.rmtree(proj)
        session.call("project.create", location=str(dest), name=name,
                     video={"width": 1280, "height": 720, "rateNum": 30, "rateDen": 1})
        path = str(proj)
        vid = session.created_id(session.call("media.import", path=path, file=str(videos[0])))
        mid = session.created_id(session.call("media.import", path=path, file=str(music)))
        sid = session.created_id(session.call("media.import", path=path, file=str(sfx)))
        # confirm probes saw audio
        probe_m = session.call("media.probe", path=str(music))
        probe_s = session.call("media.probe", path=str(sfx))
        session.edit(path, "addTrack")
        session.edit(path, "addTrack")
        doc = session.call("project.get", path=path)
        tracks = [tr["id"] for tr in doc["project"]["timelines"][0]["tracks"]]
        v = session.created_id(session.edit(path, "addClip", mediaId=vid, trackId=tracks[0], start=0.0))
        m = session.created_id(session.edit(path, "addClip", mediaId=mid, trackId=tracks[1], start=0.0))
        s = session.created_id(session.edit(path, "addClip", mediaId=sid, trackId=tracks[2], start=1.2))
        session.edit(path, "updateClip", clipId=m, patch={"volume": 0.55, "fadeIn": 0.4, "fadeOut": 0.5})
        session.edit(path, "updateClip", clipId=s, patch={"volume": 0.9, "fadeIn": 0.02, "fadeOut": 0.08})
        session.edit(path, "duckAudio", musicId=m, triggerId=s, amount=0.12, attack=0.08, release=0.4)
        session.call("project.save", path=path)
        exported = session.export_and_wait(path, str(out), crf=28, width=1280, height=720, rateNum=30, rateDen=1)
        report.update({
            "ok": True, "path": path, "output": str(out),
            "outputBytes": out.stat().st_size if out.exists() else 0,
            "musicId": mid, "sfxId": sid, "videoClip": v, "sfxClip": s,
            "probeMusic": probe_m, "probeSfx": probe_s,
            "ducking": "duckAudio music under SFX amount=0.12 attack=0.08 release=0.4",
            "fades": {"music": {"fadeIn": 0.4, "fadeOut": 0.5}, "sfx": {"fadeIn": 0.02, "fadeOut": 0.08}},
            "totalSeconds": round(time.perf_counter() - t0, 3),
            "peakRssKiB": sampler.stop(),
            "exportReply": exported,
        })
    except Exception as exc:
        sampler.stop()
        report["error"] = str(exc)
        report["peakRssKiB"] = sampler.peak
        report["totalSeconds"] = round(time.perf_counter() - t0, 3)
        report["stderr"] = session.stderr_tail[-30:]
    finally:
        session.close()
    return report



def as_list(value) -> list:
    return value if isinstance(value, list) else []


def run_presets_phase() -> dict:
    """Apply every 花字 and 文字模板 once via addTextClip. No full encode."""
    dest = M7 / "presets"
    dest.mkdir(parents=True, exist_ok=True)
    report = {"phase": "presets", "ok": False, "error": None, "failed": []}
    session = Session()
    sampler = Sampler(session.proc.pid)
    sampler.start()
    t0 = time.perf_counter()
    try:
        name = "presets"
        proj = dest / name
        if proj.exists():
            shutil.rmtree(proj)
        session.call(
            "project.create",
            location=str(dest),
            name=name,
            video={"width": 1280, "height": 720, "rateNum": 30, "rateDen": 1},
        )
        path = str(proj)
        for _ in range(6):
            session.edit(path, "addTrack")
        huazi = as_list(session.call("presets.list", category="huazi"))
        templates = as_list(session.call("presets.list", category="template"))
        listed = huazi + templates
        if not listed:
            raise RuntimeError("presets.list returned no 花字 or 文字模板")
        failed = []
        applied = 0
        seen = set()
        for i, preset in enumerate(listed):
            pid = preset.get("id") or ""
            if not pid or pid in seen:
                continue
            seen.add(pid)
            try:
                style = read_preset(pid)
            except FileNotFoundError as exc:
                failed.append({"id": pid, "error": str(exc)})
                continue
            style["content"] = style.get("content") or style.get("_name") or pid
            got = session.try_edit(
                path,
                "addTextClip",
                start=(i % 80) * 0.05,
                duration=0.4,
                above=True,
                offsetY=-0.25 + (i % 7) * 0.08,
                style={k: v for k, v in style.items() if not str(k).startswith("_")},
            )
            if got.get("ok"):
                applied += 1
            else:
                failed.append({"id": pid, "category": preset.get("category"), "error": got.get("error")})
        session.call("project.save", path=path)
        doc = session.call("project.get", path=path)
        n_clips = len(doc["project"]["timelines"][0]["clips"])
        report.update({
            "ok": len(failed) == 0,
            "path": path,
            "listed": len(listed),
            "huazi": len(huazi),
            "templates": len(templates),
            "applied": applied,
            "clips": n_clips,
            "failedCount": len(failed),
            "failed": failed[:40],
            "totalSeconds": round(time.perf_counter() - t0, 3),
            "peakRssKiB": sampler.stop(),
        })
        if failed:
            report["error"] = f"{len(failed)} presets failed to apply"
    except Exception as exc:
        sampler.stop()
        report["error"] = str(exc)
        report["peakRssKiB"] = sampler.peak
        report["totalSeconds"] = round(time.perf_counter() - t0, 3)
        report["stderr"] = session.stderr_tail[-30:]
    finally:
        session.close()
    return report


def run_captions_phase() -> dict:
    """captions.transcribe against English (JFK / existing) and Chinese if present."""
    dest = M7 / "captions"
    dest.mkdir(parents=True, exist_ok=True)
    report = {"phase": "captions", "ok": False, "error": None}
    session = Session()
    t0 = time.perf_counter()
    try:
        en = Path.home() / ".local/share/app.marquee.editor/samples/jfk.wav"
        m6_en = M6 / "captions"
        candidates = [
            en,
            m6_en / "jfk.wav",
            dest / "jfk.wav",
        ]
        en_file = next((c for c in candidates if c.is_file()), None)
        # Prefer any earlier M6 captured wav
        if en_file is None:
            for folder in (M6 / "captions", dest):
                if folder.is_dir():
                    for wav in sorted(folder.glob("*.wav")):
                        en_file = wav
                        break
        zh_file = dest / "zh-sample.wav"
        if not zh_file.is_file():
            for folder in (M6 / "captions", dest):
                for name in ("zh-sample.wav", "zh.wav", "chinese.wav"):
                    cand = folder / name
                    if cand.is_file():
                        zh_file = cand
                        break
        en_result = None
        if en_file is not None:
            en_result = session.call(
                "captions.transcribe",
                file=str(en_file),
                model="tiny.en",
                language="en",
            )
        zh_result = None
        zh_model = None
        if zh_file.is_file():
            zh_model = "base"
            zh_result = session.call(
                "captions.transcribe",
                file=str(zh_file),
                model="base",
                language="zh",
            )
        report.update({
            "ok": bool(en_result) or bool(zh_result),
            "enFile": str(en_file) if en_file else None,
            "enCues": len(en_result) if isinstance(en_result, list) else 0,
            "enPreview": (en_result or [])[:4],
            "zhFile": str(zh_file) if zh_file.is_file() else None,
            "zhModel": zh_model,
            "zhCues": len(zh_result) if isinstance(zh_result, list) else 0,
            "zhPreview": (zh_result or [])[:4],
            "zhObtained": zh_file.is_file(),
            "totalSeconds": round(time.perf_counter() - t0, 3),
        })
        if not report["ok"]:
            report["error"] = "no audio file transcribed"
        (dest / "captions-report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n"
        )
    except Exception as exc:
        report["error"] = str(exc)
        report["totalSeconds"] = round(time.perf_counter() - t0, 3)
        report["stderr"] = session.stderr_tail[-40:]
    finally:
        session.close()
    return report


def main(argv: list[str]) -> int:
    phases = argv[1:] or ["smoke", "stress"]
    allowed = {"smoke", "stress", "sku", "audio", "presets", "captions"}
    for phase in phases:
        if phase not in allowed:
            print(f"usage: {argv[0]} [smoke] [stress] [sku] [audio] [presets] [captions]", file=sys.stderr)
            return 2
    results = []
    code = 0
    for phase in phases:
        print(f"=== {phase} ===", flush=True)
        if phase == "sku":
            result = run_sku_phase()
        elif phase == "audio":
            result = run_audio_phase()
        elif phase == "presets":
            result = run_presets_phase()
        elif phase == "captions":
            result = run_captions_phase()
        else:
            result = run_phase(phase)
        results.append(result)
        print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
        if not result.get("ok"):
            code = 1
            break
    metrics_root = M7 if any(r.get("phase") in {"sku", "audio", "presets", "captions"} for r in results) else (
        M6 if any(r.get("phase") in {"sku", "audio"} for r in results) else M5
    )
    metrics_root.mkdir(parents=True, exist_ok=True)
    metrics_path = metrics_root / "metrics.json"
    merged = []
    if metrics_path.exists():
        try:
            prev = json.loads(metrics_path.read_text())
            merged = list(prev.get("results") or [])
        except (json.JSONDecodeError, OSError):
            merged = []
    by_phase = {row.get("phase"): row for row in merged if isinstance(row, dict)}
    for row in results:
        by_phase[row.get("phase")] = row
    order = ["smoke", "stress", "sku", "audio", "presets", "captions"]
    written = [by_phase[name] for name in order if name in by_phase]
    written += [row for name, row in by_phase.items() if name not in order]
    metrics_path.write_text(
        json.dumps({"when": time.strftime("%Y-%m-%d %H:%M %Z"), "results": written}, indent=2)
        + "\n"
    )
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv))
