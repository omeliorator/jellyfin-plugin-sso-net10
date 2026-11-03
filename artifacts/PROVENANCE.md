# Artifact provenance — sso-authentication_4.1.1.0.zip

Pinned digest (the artifact to install):

    sha256   996d5e2c4d28745fbfad75c67c2b9bf9d91acf64ad4ff75c65f92f40e555f052
    built    commit 4ff10bfd, GitHub Actions run 41652558835, workflow "Plugin build (net10 / Jellyfin 12.x)"
    SDK      10.0.403 on ubuntu-latest (setup-dotnet 10.0.x)
    size     180872 bytes
    contents SSO-Auth.dll, Duende.IdentityModel.dll, Duende.IdentityModel.OidcClient.dll, meta.json

Verified before pinning: the zip was downloaded from that CI run, its sha256
recomputed locally (match), unpacked into an **empty** `/config` on Jellyfin
12.4.0, and the server logged `Loaded plugin: SSO-Auth 4.1.1.0` with no
`NotSupported`.

## Reproducibility — what is and is not true

- Two clean checkouts of the **same tree** on the **same toolchain** build an
  identical `SSO-Auth.dll` (verified locally with
  `-p:ContinuousIntegrationBuild=true -p:Deterministic=true`).
- Two CI runs are **not** identical: the runner embeds the git commit id
  (`SourceRevisionId`) and `meta.json` carries a timestamp derived from the
  commit date, so a new commit produces a different DLL and a different zip.
  Measured: run 41652558835 → `996d5e2c…`, run 41654603009 → `2356a3e6…`, and
  the two `SSO-Auth.dll` hashes differ (5700d62e… vs af6906c4…).
- Therefore **pinning means pinning one specific build**, not "the build is
  deterministic". If CI is re-run, the new digest must be re-recorded and, before
  a production install, re-verified. Do not treat this file as a fingerprint of
  the source tree.

The IntroSkipper artifact is built by `scripts/build_introskipper.sh`, which
pins the **upstream DLL** by digest inside the script (`4d97b909…`) — that part
is content-addressed and stable. Its own zip digest is recorded in the task
report because it is not produced by CI.
