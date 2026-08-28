# Public Release Checklist

This checklist tracks the remaining repository settings and release evidence required for public source publication and downloadable app distribution.

## Already Ready In The Repo

- MIT license, code of conduct, contributing, support, security, privacy, and release docs are present.
- CI runs lint, docs, scripts, SwiftPM tests, Xcode tests, Release build, analyzer, CLI dry run, package dry run, appcast dry run, and Sparkle signing dry run.
- README screenshots, social-preview image, app icon, issue templates, and release scripts are present.
- Source install instructions are clear while signed app downloads are pending.
- Simulator filesystem cleanup is blocked in the scanner, planner, and executor; simulator delete/erase preflight identifies irreversible data removal.
- Complete DELTREE, Sparkle, and bundled-component license notices are included in the app bundle and enforced by release artifact checks.

## Do Before Making The Source Public

1. Set the GitHub repository social preview image to `docs/assets/screenshots/social-preview.png`.
2. Confirm every custom label in `.github/labels.yml` exists on GitHub; standard GitHub default labels may remain in addition.
3. Confirm the latest `main` CI run is green.
4. Confirm `make check` and `make ui-test` pass locally.
5. Confirm there are no committed secrets or private local paths in docs or fixtures.
6. Change the repository visibility to public.
7. Immediately after public visibility is available, protect `main` with required PRs and required CI checks.

## Do Before Publishing Downloadable Apps

Signed downloadable apps are released from a designated maintainer Mac using [Local-Only Release Setup](LOCAL_RELEASE.md). Before the first app download is published:

1. Install the Developer ID Application certificate and private key in this Mac's Keychain.
2. Create the App Store Connect API key used only for notarization.
3. Store the notarytool profile in Keychain with `Scripts/setup-local-release-secrets.sh`.
4. Generate the Sparkle EdDSA key in Keychain and save only the public key in `~/.config/deltree/release.env`.
5. Run `Scripts/release-local.sh <tag> --repo hazennik/DELTREE --draft`.
6. Complete [Release QA](RELEASE_QA.md) against the draft release artifact.
7. Publish the GitHub Release only after the notarized app, appcast, checksums, and update flow pass.

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
