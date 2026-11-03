#!/usr/bin/env bash
# Build a sideload-ready IntroSkipper 12.0.6.0 zip for Jellyfin 12.4.
#
# The upstream release (12.0/v12.0.6.0) ships only IntroSkipper.dll — no
# meta.json — and its guid is not in the official Jellyfin manifest, so it
# cannot be installed by the repository mechanism. We pin the upstream DLL by
# sha256 and ship our own manifest next to it (see introskipper/meta.json).
#
# Decision recorded in FORK.md §IntroSkipper (DES-007-jellyfin-12-sso-auth.md §10.2 R2).
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="12.0.6.0"
URL="https://github.com/intro-skipper/intro-skipper/releases/download/12.0/v${VERSION}/intro-skipper-v${VERSION}.zip"
DLL_SHA256="4d97b9098c3d67d907ab94bac850558ef97ff0ebe2bd956e8e2718720101c221"

OUT="dist/intro-skipper_${VERSION}.zip"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

curl -fsSL -o "$WORK/upstream.zip" "$URL"
unzip -q -o "$WORK/upstream.zip" -d "$WORK/upstream"

got="$(sha256sum "$WORK/upstream/IntroSkipper.dll" | cut -d' ' -f1)"
[ "$got" = "$DLL_SHA256" ] || { echo "FAIL: IntroSkipper.dll sha256 $got != pinned $DLL_SHA256"; exit 1; }
echo "ok: upstream IntroSkipper.dll matches pinned sha256 $DLL_SHA256"

mkdir -p "$WORK/stage" dist
cp "$WORK/upstream/IntroSkipper.dll" "$WORK/stage/"
cp introskipper/meta.json "$WORK/stage/meta.json"

python3 scripts/zip_artifact.py "$WORK/stage" "$OUT" "$(git log -1 --format=%ct)" \
  IntroSkipper.dll meta.json
(cd dist && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256")
cat "dist/$(basename "$OUT").sha256"
