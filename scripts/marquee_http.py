#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Tiny local HTTP front for concat-cli api (one process).

  python3 scripts/marquee_http.py --port 8765
  python3 scripts/marquee_http.py --token "$MARQUEE_HTTP_TOKEN"

POST /rpc          JSON body { "method": "...", ... }  →  JSON-RPC result
GET  /health
GET  /catalogue?kind=effect
GET  /presets?category=huazi&query=珊瑚

Every route needs the shared token, sent as one of:
  Authorization: Bearer <token>
  X-Marquee-Token: <token>
  ?token=<token>

`--token` wins; else MARQUEE_HTTP_TOKEN; else a random hex is printed once.
"""

from __future__ import annotations

import argparse
import json
import os
import secrets
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from marquee_agent import Session  # noqa: E402


SESSION = Session()
TOKEN = ""


def provided_token(handler: BaseHTTPRequestHandler, qs: dict[str, list[str]]) -> str:
    auth = handler.headers.get("Authorization") or ""
    if auth.lower().startswith("bearer "):
        return auth[7:].strip()
    header = (handler.headers.get("X-Marquee-Token") or "").strip()
    if header:
        return header
    return (qs.get("token") or [""])[0]


def token_ok(handler: BaseHTTPRequestHandler, qs: dict[str, list[str]]) -> bool:
    got = provided_token(handler, qs)
    if not TOKEN or not got:
        return False
    return secrets.compare_digest(got, TOKEN)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send(self, code: int, payload) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _auth(self, qs: dict[str, list[str]]) -> bool:
        if token_ok(self, qs):
            return True
        self._send(401, {"error": "unauthorized"})
        return False

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        qs = parse_qs(parsed.query)
        if not self._auth(qs):
            return
        if parsed.path == "/health":
            self._send(200, {"ok": True, "service": "幕次"})
            return
        if parsed.path == "/catalogue":
            kind = (qs.get("kind") or [None])[0]
            try:
                result = SESSION.call("catalogue.list", **({"kind": kind} if kind else {}))
                self._send(200, result)
            except Exception as exc:
                self._send(400, {"error": str(exc)})
            return
        if parsed.path == "/presets":
            args = {}
            if qs.get("category"):
                args["category"] = qs["category"][0]
            if qs.get("query"):
                args["query"] = qs["query"][0]
            try:
                result = SESSION.call("presets.list", **args)
                self._send(200, result)
            except Exception as exc:
                self._send(400, {"error": str(exc)})
            return
        self._send(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        qs = parse_qs(parsed.query)
        if not self._auth(qs):
            return
        if parsed.path != "/rpc":
            self._send(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length)
        try:
            rec = json.loads(raw.decode())
            method = rec.pop("method")
            result = SESSION.call(method, **rec)
            self._send(200, {"result": result})
        except Exception as exc:
            self._send(400, {"error": str(exc)})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument(
        "--token",
        default=os.environ.get("MARQUEE_HTTP_TOKEN") or "",
        help="shared secret; MARQUEE_HTTP_TOKEN if omitted; random hex otherwise",
    )
    args = parser.parse_args()
    global TOKEN
    TOKEN = args.token.strip() or secrets.token_hex(16)
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(
        f"幕次 HTTP api on http://{args.host}:{args.port}  (POST /rpc)",
        flush=True,
    )
    print(f"token required (Authorization Bearer / X-Marquee-Token / ?token=)", flush=True)
    if not args.token.strip() and not os.environ.get("MARQUEE_HTTP_TOKEN"):
        print(f"generated token: {TOKEN}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        SESSION.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
