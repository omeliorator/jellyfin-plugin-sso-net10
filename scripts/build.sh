#!/usr/bin/env bash
# Build sso-authentication_<version>.zip from a clean checkout.
#
# Deterministic packaging: the zip is written by scripts/zip_artifact.py with a
# fixed mtime (the commit date) and a fixed entry order, so the archive layout
# depends only on the file contents and the commit. (The DLL itself is not
# byte-reproducible: Roslyn embeds fresh MVIDs.)
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="$(sed -n 's/^version: "\(.*\)"$/\1/p' build.yaml)"
ZIP="dist/sso-authentication_${VERSION}.zip"

rm -rf dist
mkdir -p dist/stage

dotnet publish SSO-Auth/SSO-Auth.csproj -c Release -o dist/publish --nologo \
  -p:ContinuousIntegrationBuild=true -p:Deterministic=true

python3 scripts/gen_meta.py > /dev/null
cp dist/meta.json dist/stage/meta.json
for f in SSO-Auth.dll Duende.IdentityModel.dll Duende.IdentityModel.OidcClient.dll; do
  cp "dist/publish/$f" "dist/stage/$f"
done

python3 scripts/zip_artifact.py "dist/stage" "$ZIP" "${SOURCE_DATE_EPOCH:-$(git log -1 --format=%ct)}"
rm -rf dist/stage

(cd dist && sha256sum "$(basename "$ZIP")" > "$(basename "$ZIP").sha256")
cat "dist/$(basename "$ZIP").sha256"
