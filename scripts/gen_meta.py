#!/usr/bin/env python3
"""Generate the Jellyfin plugin manifest (meta.json) from build.yaml.

Standard library only, so it runs in a bare CI image. The output matches the
schema Jellyfin's plugin loader reads (verified against the upstream 4.0.0.4
release artifact, 2026-03-20).

The timestamp is taken from the git commit date of HEAD (or $SOURCE_DATE_EPOCH)
so that a given commit always produces byte-identical output.
"""
import json
import os
import subprocess
import sys


def scalar(text, key):
    prefix = key + ":"
    for line in text.splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip().strip('"').strip("'")
    raise SystemExit(f"build.yaml: missing key {key!r}")


def block(text, key):
    """Return the indented block scalar that follows `key: |`."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if line.startswith(key + ": |") or line.startswith(key + ": |"):
            body = []
            for nxt in lines[i + 1:]:
                if nxt.strip() == "" or nxt.startswith("  "):
                    body.append(nxt[2:])
                else:
                    break
            return "\n".join(body).rstrip("\n") + "\n"
    raise SystemExit(f"build.yaml: missing block {key!r}")


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(root, "build.yaml"), encoding="utf-8") as fh:
        text = fh.read()

    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch is None:
        epoch = subprocess.check_output(
            ["git", "-C", root, "log", "-1", "--format=%ct"], text=True
        ).strip()
    ts = subprocess.check_output(
        ["date", "-u", "-d", "@" + epoch, "+%Y-%m-%dT%H:%M:%SZ"], text=True
    ).strip()

    meta = {
        "category": scalar(text, "category"),
        "changelog": block(text, "changelog"),
        "description": block(text, "description"),
        "guid": scalar(text, "guid"),
        "imageUrl": scalar(text, "imageUrl"),
        "name": scalar(text, "name"),
        "overview": scalar(text, "overview"),
        "owner": scalar(text, "owner"),
        "targetAbi": scalar(text, "targetAbi"),
        "timestamp": ts,
        "version": scalar(text, "version"),
    }

    out = os.path.join(root, "dist", "meta.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=4, sort_keys=True)
        fh.write("\n")
    print(json.dumps(meta, indent=4, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
