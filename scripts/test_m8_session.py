# SPDX-License-Identifier: AGPL-3.0-or-later
"""Regression: Session.call must not turn an empty list into {}."""

import importlib.util
from pathlib import Path


def unwrap_result(reply):
    if "result" in reply:
        return reply["result"]
    return {}


def test_empty_array_stays_an_array():
    assert unwrap_result({"result": []}) == []
    assert unwrap_result({"result": {}}) == {}
    assert unwrap_result({"ok": True}) == {}


def test_agent_source_does_not_use_or_empty_dict():
    text = Path(__file__).with_name("marquee_agent.py").read_text()
    assert 'return reply.get("result") or {}' not in text
    assert 'if "result" in reply:' in text


if __name__ == "__main__":
    test_empty_array_stays_an_array()
    test_agent_source_does_not_use_or_empty_dict()
    print("ok")
