# Releasing

DELTREE is intended for Developer ID distribution outside the Mac App Store.

## Prerequisites

- Developer ID Application certificate installed locally.
- Apple Developer Team ID.
- Notarization keychain profile configured for `xcrun notarytool`.
- Sparkle EdDSA public key, Keychain-backed private key, and a real HTTPS appcast URL before public updates are enabled. Release candidates require a stable prerelease-channel feed; GitHub's `/releases/latest/` redirect is for stable releases only.
- `DELTREE_DEVELOPMENT_TEAM` configured locally only when opening the Xcode project with signing enabled.

For this repository, the default production path is local-only release signing from a designated maintainer Mac. Follow [Local-Only Release Setup](LOCAL_RELEASE.md) before creating downloadable releases.

## Build And Test

```sh
make check
```

If SwiftFormat or SwiftLint are not installed locally, install them first:

```sh
brew install swiftformat swiftlint
```

## Release Preflight

Run the single-command preflight from a clean release-candidate branch:

```sh
Scripts/release-preflight.sh v1.0.0-rc.1 --repo hazennik/DELTREE
```

The preflight fails on a dirty working tree, missing or mismatched changelog notes, failed local checks, failed packaging dry-runs, appcast dry-run failures, or Sparkle signing dry-run failures.
After a GitHub Release is published, verify live assets and appcast enclosure URLs:

```sh
Scripts/release-preflight.sh v1.0.0-rc.1 --repo hazennik/DELTREE --post-publish
```

## Package

For a complete local release, use:

```sh
Scripts/release-local.sh v1.0.0-rc.1 --repo hazennik/DELTREE --draft
```

GitHub Release immutability is enabled. Complete the artifact set and QA on the draft before publication; a published tag or asset cannot be replaced, so corrections require a new version.

For packaging only:

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
DELTREE_NOTARY_PROFILE="deltree-notary-profile" \
Scripts/package-release.sh --notarize --distribution developer-id
```

The packaging script builds a signed archive and zip, submits the zip to Apple notarization when `--notarize` is present, staples the app, and recreates the zip.
The notarized `DELTREE.zip` is the downloadable app artifact. Do not publish a virtual-machine image or raw disk image. A signed and notarized `.dmg` may be added later as an optional manual-install format, but it is not required for GitHub Releases or Sparkle updates.
Developer ID is the default distribution channel. The archive writes `DELTREEDistributionChannel=developer-id` into the app Info.plist, and `DistributionChannel.allowsSparkleUpdates` returns `true` for that channel.
The same package step also verifies that the archived dSYM UUIDs match the app binary for each architecture and writes `build/export/DELTREE.dSYM.zip` with `ditto --norsrc`.
Packaging writes checksums beside the artifacts:

- `build/export/DELTREE.zip.sha256`
- `build/export/DELTREE.dSYM.zip.sha256`

CI and pull requests use dry runs to validate the command path without real credentials:

```sh
make package-check
make appcast-check
```

## Appcast

Validate the changelog, generate the Sparkle EdDSA signature from the final notarized zip, then generate the appcast:

```sh
Scripts/validate-changelog.sh v1.0.0-rc.1 \
  --notes-output build/release/release-notes.md \
  --html-output build/release/release-notes.html

DELTREE_SPARKLE_PRIVATE_KEY_FILE="/path/to/sparkle-private-key" \
Scripts/sign-sparkle-update.sh --zip build/export/DELTREE.zip --env-output build/release/sparkle.env

source build/release/sparkle.env

DELTREE_RELEASE_VERSION="1.0.0-rc.1" \
DELTREE_MARKETING_VERSION="1.0.0" \
DELTREE_BUILD_VERSION="42" \
DELTREE_RELEASE_ZIP_URL="https://github.com/hazennik/DELTREE/releases/download/v1.0.0-rc.1/DELTREE.zip" \
DELTREE_RELEASE_NOTES_HTML_PATH="build/release/release-notes.html" \
Scripts/generate-appcast.sh
```

The appcast is written to `build/export/appcast.xml` by default.

## dSYM Symbols

`Scripts/package-release.sh` packages `build/export/DELTREE.dSYM.zip` from the Xcode archive. The script locates `DELTREE.xcarchive/dSYMs/DELTREE.app.dSYM`, compares `dwarfdump --uuid` output against `DELTREE.app/Contents/MacOS/DELTREE`, and fails the release if any architecture UUID is missing or mismatched.

Upload `DELTREE.dSYM.zip` with every release. It is not part of the Sparkle appcast payload, but it is required for future crash symbolication.

## GitHub Release Automation

The default release path does not use GitHub-hosted signing. The `Release` workflow is present for future automation, but the job is skipped unless repository variable `DELTREE_RELEASE_EXECUTOR` is set to `github-actions`.

If hosted signing is enabled later, the `Release` workflow runs on `v*` tags and manual dispatch. It expects these repository secrets:

- `DELTREE_DEVELOPER_ID_CERTIFICATE_BASE64`
- `DELTREE_DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `DELTREE_KEYCHAIN_PASSWORD`
- `DELTREE_DEVELOPER_ID_APPLICATION`
- `DELTREE_TEAM_ID`
- `DELTREE_APP_STORE_CONNECT_KEY_ID`
- `DELTREE_APP_STORE_CONNECT_ISSUER_ID`
- `DELTREE_APP_STORE_CONNECT_API_KEY_BASE64`
- `DELTREE_SPARKLE_PRIVATE_KEY_BASE64`

It also expects these repository variables:

- `DELTREE_SPARKLE_PUBLIC_ED_KEY`
- `DELTREE_SPARKLE_FEED_URL`; stable releases may use `https://github.com/hazennik/DELTREE/releases/latest/download/appcast.xml`, while release candidates require a stable prerelease-channel URL

Set `DELTREE_RELEASE_ZIP_URL` as a repository variable if release assets are hosted somewhere other than GitHub Releases.

The workflow validates the matching `CHANGELOG.md` section, signs/notarizes/staples the app, generates checksums, signs the Sparkle update, publishes GitHub Release assets, and then runs:

```sh
Scripts/check-release-assets.sh "$DELTREE_RELEASE_TAG" --repo "$GITHUB_REPOSITORY"
```

## Credential Safety

Apple Developer and Sparkle credentials must never be committed to the repository. For the default release path, store them only in local Keychain/private files on the designated maintainer Mac.

The hosted release workflow is intentionally separate from pull-request CI and is opt-in. Normal public pull requests do not receive Developer ID, notarization, or Sparkle private-key material.

In local release mode, the Developer ID certificate, notarytool profile, and Sparkle update-signing key stay in this Mac's Keychain. The local env file stores IDs, paths, and public values only.

If hosted signing is enabled later, the Developer ID certificate is imported into a temporary GitHub Actions keychain during the release job. The App Store Connect API key is decoded into the runner's temporary directory for notarization, and the Sparkle private key is used only to sign the final update zip.

If any signing credential is exposed or suspected to be exposed, revoke it in Apple Developer or App Store Connect, rotate the matching GitHub secret, and rerun release validation with a new build.

## Homebrew

Homebrew Cask distribution should wait until signed, notarized GitHub Releases and Sparkle appcasts are stable. The cask will need the release zip URL, SHA-256 checksum, bundle identifier, and uninstall/zap paths.

Build Homebrew artifacts with the explicit Homebrew channel:

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
DELTREE_NOTARY_PROFILE="deltree-notary-profile" \
Scripts/package-release.sh --notarize --distribution homebrew
```

Homebrew builds write `DELTREEDistributionChannel=homebrew` into the app, create `build/export/DELTREE-homebrew.zip`, and `DistributionChannel.allowsSparkleUpdates` returns `false`, so Homebrew-managed apps do not self-update through Sparkle.

## Release Checklist

- Confirm cleanup safety tests pass.
- Run `Scripts/release-preflight.sh <tag> --repo hazennik/DELTREE` from a clean branch.
- Confirm manual scan on a machine with Xcode installed.
- Confirm CLI dry run.
- Confirm no production hard-delete path.
- Confirm `DELTREE.xcodeproj` does not contain a personal hardcoded Team ID.
- Sign and notarize with Developer ID.
- Confirm the selected distribution channel matches the release artifact owner.
- Validate the matching dated `CHANGELOG.md` section.
- Generate Sparkle appcast only after signing the final zip.
- Attach `DELTREE.zip`, `DELTREE.zip.sha256`, `DELTREE.dSYM.zip`, `DELTREE.dSYM.zip.sha256`, and `appcast.xml` to the GitHub Release.
- Run `Scripts/release-preflight.sh <tag> --repo hazennik/DELTREE --post-publish` against the published release.
- Complete [Release QA](RELEASE_QA.md) before marking the release public GA.
