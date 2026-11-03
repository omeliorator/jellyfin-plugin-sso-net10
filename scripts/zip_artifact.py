#!/usr/bin/env python3
"""Deterministic zip writer for the plugin artifact.

Usage: zip_artifact.py <stagedir> <out.zip> <epoch-seconds>

Entries are written in a fixed order with a fixed timestamp, so the archive
bytes depend only on the file contents and the commit date — not on the
filesystem's mtimes or the host's zip implementation.
"""
import os
import sys
import time
import zipfile

NAMES = [
    "SSO-Auth.dll",
    "Duende.IdentityModel.dll",
    "Duende.IdentityModel.OidcClient.dll",
    "meta.json",
]


def main():
    stage, out, epoch = sys.argv[1], sys.argv[2], int(sys.argv[3])
    stamp = time.gmtime(epoch)[:6]
    if stamp[0] < 1980:  # zip format floor
        stamp = (1980, 1, 1, 0, 0, 0)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for name in NAMES:
            path = os.path.join(stage, name)
            if not os.path.exists(path):
                raise SystemExit(f"missing staged file: {path}")
            info = zipfile.ZipInfo(name, date_time=stamp)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            info.create_system = 3
            with open(path, "rb") as fh:
                zf.writestr(info, fh.read())
    print(out)


if __name__ == "__main__":
    main()
