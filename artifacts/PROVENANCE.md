# Artifact provenance — sso-authentication_4.1.1.0.zip

Pinned digest (the artifact to install):

    sha256  996d5e2c4d28745fbfad75c67c2b9bf9d91acf64ad4ff75c65f92f40e555f052
    built   GitHub Actions run 41652558835, commit 4ff10bfd, workflow "Plugin build (net10 / Jellyfin 12.x)"
    size    180872 bytes
    contents SSO-Auth.dll, Duende.IdentityModel.dll, Duende.IdentityModel.OidcClient.dll, meta.json

Verified: the pinned bytes were downloaded from the CI run, the sha256 recomputed
locally (matches), unpacked into an empty /config on Jellyfin 12.4.0, and the log
shows `Loaded plugin: SSO-Auth 4.1.1.0` with no `NotSupported`.

Byte-reproducibility note: `ContinuousIntegrationBuild=true` makes two clean
checkouts on the *same* toolchain produce an identical SSO-Auth.dll (verified),
but a local build (SDK 10.0.403) and the GitHub runner do not yet agree
bit-for-bit — 0a4a5af9… locally vs 996d5e2c… in CI. Pin the CI artifact, not a
local one; if the build is re-run, the digest changes and must be re-pinned.

The IntroSkipper artifact is built by scripts/build_introskipper.sh and pins the
upstream DLL by digest inside the script (4d97b909…); its zip digest is recorded
in the task report, not here, because it is not produced by CI.
