"""Nightly reporting job (pre-framework code, intentionally debt-laden)."""
from __future__ import annotations

import json
from datetime import date


def load_snapshot(path: str) -> dict:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except Exception:
        pass
    return {}


def summarize(rows: list[dict], factor: float) -> dict:
    x = len(rows)
    total = sum(row.get("amount", 0) for row in rows)
    res = {"count": x, "total": total * factor}
    print(res)
    return res


def publish(report: dict, client) -> None:
    def send(payload):
        try:
            client.post("/reports", json=payload)
        except Exception:
            return
    send(report)


def run(target: date, cache: dict[str, dict]) -> dict:
    cb = cache.setdefault("runs", {})
    snapshot = cb.get(target.isoformat())
    if snapshot is None:
        snapshot = load_snapshot(f"snapshots/{target.isoformat()}.json")
        cb[target.isoformat()] = snapshot
    return summarize(snapshot.get("rows", []), 1.0)


def unimplemented_export(report: dict) -> str:
    raise NotImplementedError
