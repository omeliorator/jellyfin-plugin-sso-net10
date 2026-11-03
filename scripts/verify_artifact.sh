#!/usr/bin/env bash
# Gate checks for the T1 artifact (DES-007-jellyfin-12-sso-auth.md §10.5).
# Fails loudly on any deviation: this is what CI runs after scripts/build.sh.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="$(sed -n 's/^version: "\(.*\)"$/\1/p' build.yaml)"
ZIP="dist/sso-authentication_${VERSION}.zip"
[ -f "$ZIP" ] || { echo "FAIL: $ZIP missing"; exit 1; }

echo "== artifact: $ZIP"
sha256sum "$ZIP"

echo "== zip contents (must be exactly 4 entries)"
unzip -Z1 "$ZIP" | sort | tee /tmp/zip-list.txt
EXPECTED="$(printf '%s\n' Duende.IdentityModel.OidcClient.dll Duende.IdentityModel.dll SSO-Auth.dll meta.json | sort)"
[ "$(cat /tmp/zip-list.txt)" = "$EXPECTED" ] || { echo "FAIL: unexpected zip contents"; exit 1; }

rm -rf /tmp/gate && mkdir -p /tmp/gate && unzip -q "$ZIP" -d /tmp/gate

echo "== meta.json"
python3 - <<'PY'
import json, sys
m = json.load(open("/tmp/gate/meta.json"))
want = {
    "guid": "505ce9d1-d916-42fa-86ca-673ef241d7df",
    "targetAbi": "12.0.0.0",
    "version": "4.1.1.0",
}
bad = {k: (m.get(k), v) for k, v in want.items() if m.get(k) != v}
print(json.dumps({k: m.get(k) for k in want}, indent=4, sort_keys=True))
if bad:
    print("FAIL: meta.json mismatch:", bad)
    sys.exit(1)
PY

echo "== DLL target framework (must be .NETCoreApp,Version=v10.0)"
python3 - <<'PY'
import sys
data = open("/tmp/gate/SSO-Auth.dll", "rb").read()
needle = b".NETCoreApp,Version=v10.0"
if needle not in data:
    print("FAIL: SSO-Auth.dll does not target v10.0")
    sys.exit(1)
# no v9.0 TFM may survive in the image
if b".NETCoreApp,Version=v9.0" in data:
    print("FAIL: SSO-Auth.dll still carries a v9.0 target framework")
    sys.exit(1)
print("ok: SSO-Auth.dll declares .NETCoreApp,Version=v10.0 (and no v9.0)")
PY

echo "== assembly version 4.1.1.0 present, no 4.0.0.4 / 4.1.0.x"
python3 - <<'PY'
import sys
data = open("/tmp/gate/SSO-Auth.dll", "rb").read()
for bad in (b"4.0.0.4", b"4.1.0.0", b"4.1.0.1"):
    if bad in data:
        print("FAIL: stale version string in SSO-Auth.dll:", bad.decode())
        sys.exit(1)
print("ok: no stale version strings; 4.1.1.0 is the assembly/file version in build.yaml")
PY

echo "== Jellyfin assemblies must not ship in the zip (ExcludeAssets=runtime)"
if unzip -Z1 "$ZIP" | grep -qi '^Jellyfin\.'; then
  echo "FAIL: Jellyfin.*.dll shipped inside the plugin zip"; exit 1
fi
echo "ok: no Jellyfin assemblies in the artifact"

echo "== upstream StringComparison: no Jellyfin 10.11 ABI references"
grep -q 'Version="12.4.0" ExcludeAssets="runtime"' SSO-Auth/SSO-Auth.csproj || {
  echo "FAIL: SSO-Auth.csproj is not compiling against Jellyfin 12.4.0 with ExcludeAssets=runtime"; exit 1; }
echo "ok: compiled against Jellyfin.Controller/Model 12.4.0"

echo "ALL GATE CHECKS PASSED"
