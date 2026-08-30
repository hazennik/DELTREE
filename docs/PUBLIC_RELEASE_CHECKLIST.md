# Public Release Checklist

This checklist records completed public-source work and the remaining evidence required for downloadable app distribution.

## Already Ready In The Repo

- MIT license, code of conduct, contributing, support, security, privacy, and release docs are present.
- CI runs lint, docs, scripts, SwiftPM tests, Xcode tests, Release build, analyzer, CLI dry run, package dry run, appcast dry run, and Sparkle signing dry run.
- README screenshots, social-preview image, app icon, issue templates, and release scripts are present.
- Source install instructions are clear while signed app downloads are pending.
- Simulator filesystem cleanup is blocked in the scanner, planner, and executor; simulator delete/erase preflight identifies irreversible data removal.
- Complete DELTREE, Sparkle, and bundled-component license notices are included in the app bundle and enforced by release artifact checks.

## Public Source State

- [x] The repository is public.
- [x] The social preview uses `docs/assets/screenshots/social-preview.png`.
- [x] Every custom label in `.github/labels.yml` exists on GitHub.
- [x] `main` requires pull requests, verified commit signatures, and the full CI gate with administrator enforcement.
- [x] Pull requests from other authors require one code-owner approval. Only the repository owner can bypass that review rule, and only through an auditable pull request merge; technical and integrity gates remain mandatory.
- [x] Merges are squash-only, merged branches are deleted, and automatic merging is disabled.
- [x] GitHub Actions permits only GitHub-owned actions and requires full commit-SHA pins.
- [x] Future `v*` tags are protected from updates and deletion.
- [x] Future GitHub Releases are immutable after publication.
- [x] CodeQL default setup scans Actions, Ruby, and Swift with the extended query suite.
- [x] The latest `main` CI run is green.
- [x] `make check` passes locally.
- [x] The current tree and reachable history pass the repository's private-key and token-pattern checks.
- [x] `make ui-test` passes on the trusted release Mac.

## Do Before Publishing The First Downloadable Candidate

Signed downloadable apps are released from a designated maintainer Mac using [Local-Only Release Setup](LOCAL_RELEASE.md). Before the first app download is published:

1. Install the Developer ID Application certificate and private key in this Mac's Keychain.
2. Create the App Store Connect API key used only for notarization.
3. Store the notarytool profile in Keychain with `Scripts/setup-local-release-secrets.sh`.
4. Generate the Sparkle EdDSA key in Keychain and save only the public key in `~/.config/deltree/release.env`.
5. Configure a stable prerelease-channel appcast URL; GitHub's `/releases/latest/` redirect excludes release candidates.
6. Run `Scripts/release-local.sh <tag> --repo hazennik/DELTREE --draft`.
7. Complete [Release QA](RELEASE_QA.md) against the draft release artifact.
8. Publish the GitHub prerelease only after the notarized app, appcast, checksums, and clean-machine candidate QA pass.

The first downloadable release should use the notarized `DELTREE.zip`; do not publish a virtual-machine or raw disk image. A `.dmg` is optional later and requires its own signing, notarization, and clean-machine QA.

## Do Before Public GA

The first candidate cannot update from itself. Publish a second signed candidate through the same Developer ID and Sparkle channel, then complete the RC.1-to-RC.2 update test in [Release QA](RELEASE_QA.md). Verify discovery, release notes, download, EdDSA validation, installation, and relaunch before describing Sparkle as release-tested or DELTREE as public GA.

## Optional GitHub-Hosted Signing

GitHub-hosted signing is disabled unless repository variable `DELTREE_RELEASE_EXECUTOR` is set to `github-actions`. If that mode is enabled later, signed downloadable apps require these GitHub Actions secrets:

- `DELTREE_DEVELOPER_ID_CERTIFICATE_BASE64`
- `DELTREE_DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `DELTREE_KEYCHAIN_PASSWORD`
- `DELTREE_DEVELOPER_ID_APPLICATION`
- `DELTREE_TEAM_ID`
- `DELTREE_APP_STORE_CONNECT_KEY_ID`
- `DELTREE_APP_STORE_CONNECT_ISSUER_ID`
- `DELTREE_APP_STORE_CONNECT_API_KEY_BASE64`
- `DELTREE_SPARKLE_PRIVATE_KEY_BASE64`

They also require these repository variables:

- `DELTREE_SPARKLE_PUBLIC_ED_KEY`
- `DELTREE_SPARKLE_FEED_URL`
- `DELTREE_RELEASE_ZIP_URL` only if release zips are hosted somewhere other than GitHub Releases.

## Credential Protection

Do not put Apple certificates, `.p12` files, `.p8` App Store Connect keys, Sparkle private keys, passwords, or tokens in the repo.

Use local Keychain storage for the default release path. Normal pull-request CI does not need Apple or Sparkle private material and should not receive it.

Use GitHub Actions encrypted secrets only if hosted release automation is intentionally enabled. The hosted `Release` workflow is limited to tags and manual dispatch and is gated by `DELTREE_RELEASE_EXECUTOR=github-actions`.

Use a dedicated App Store Connect API key for notarization instead of a personal Apple ID password. Keep the downloaded `.p8` file private because Apple only lets you download it once.

If a credential is ever exposed, revoke it in Apple Developer or App Store Connect, replace the matching GitHub secret, and create a fresh release build.
