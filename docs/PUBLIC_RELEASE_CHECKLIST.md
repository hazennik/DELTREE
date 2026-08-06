# Public Release Checklist

This checklist keeps the repository ready so the final source-publication step is only changing GitHub visibility from private to public.

## Already Ready In The Repo

- MIT license, code of conduct, contributing, support, security, privacy, and release docs are present.
- CI runs lint, docs, scripts, SwiftPM tests, Xcode tests, Release build, analyzer, CLI dry run, package dry run, appcast dry run, and Sparkle signing dry run.
- README screenshots, social-preview image, app icon, issue templates, and release scripts are present.
- Source install instructions are clear while signed app downloads are pending.

## Do Before Making The Source Public

1. Set the GitHub repository social preview image to `docs/assets/screenshots/social-preview.png`.
2. Confirm GitHub labels match `.github/labels.yml`.
3. Confirm the latest `main` CI run is green.
4. Confirm `make check` and `make ui-test` pass locally.
5. Confirm there are no committed secrets or private local paths in docs.
6. Change the repository visibility to public.
7. Immediately after public visibility is available, protect `main` with required PRs and required CI checks.

## Do Only If Publishing Downloadable Apps

Signed downloadable apps require these GitHub Actions secrets:

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

Use GitHub Actions encrypted secrets for release automation. Normal pull-request CI does not need these secrets and should not receive them. The `Release` workflow is limited to tags and manual dispatch so public contributors cannot trigger release signing from ordinary PRs.

Use a dedicated App Store Connect API key for notarization instead of a personal Apple ID password. Keep the downloaded `.p8` file private because Apple only lets you download it once.

If a credential is ever exposed, revoke it in Apple Developer or App Store Connect, replace the matching GitHub secret, and create a fresh release build.
