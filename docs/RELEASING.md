# Releasing

DELTREE is intended for Developer ID distribution outside the Mac App Store.

## Prerequisites

- Developer ID Application certificate installed locally.
- Apple Developer Team ID.
- Notarization keychain profile configured for `xcrun notarytool`.
- Sparkle EdDSA public key, private key file/secret, and a real appcast URL before public updates are enabled.
- `DELTREE_DEVELOPMENT_TEAM` configured locally only when opening the Xcode project with signing enabled.

## Build And Test

```sh
make check
```

If SwiftFormat or SwiftLint are not installed locally, install them first:

```sh
brew install swiftformat swiftlint
```

## Package

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
DELTREE_NOTARY_PROFILE="deltree-notary-profile" \
Scripts/package-release.sh --notarize --distribution developer-id
```

The packaging script builds a signed archive and zip, submits the zip to Apple notarization when `--notarize` is present, staples the app, and recreates the zip.
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

The `Release` workflow runs on `v*` tags and manual dispatch. It expects these repository secrets:

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
- `DELTREE_SPARKLE_FEED_URL` when not using `https://github.com/hazennik/DELTREE/releases/latest/download/appcast.xml`

Set `DELTREE_RELEASE_ZIP_URL` as a repository variable if release assets are hosted somewhere other than GitHub Releases.

The workflow validates the matching `CHANGELOG.md` section, signs/notarizes/staples the app, generates checksums, signs the Sparkle update, publishes GitHub Release assets, and then runs:

```sh
Scripts/check-release-assets.sh "$DELTREE_RELEASE_TAG" --repo "$GITHUB_REPOSITORY"
```

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
- Confirm manual scan on a machine with Xcode installed.
- Confirm CLI dry run.
- Confirm no production hard-delete path.
- Confirm `DELTREE.xcodeproj` does not contain a personal hardcoded Team ID.
- Sign and notarize with Developer ID.
- Confirm the selected distribution channel matches the release artifact owner.
- Validate the matching dated `CHANGELOG.md` section.
- Generate Sparkle appcast only after signing the final zip.
- Attach `DELTREE.zip`, `DELTREE.zip.sha256`, `DELTREE.dSYM.zip`, `DELTREE.dSYM.zip.sha256`, and `appcast.xml` to the GitHub Release.
- Run the post-release asset verifier against the published release.
- Complete [Release QA](RELEASE_QA.md) before marking the release public GA.
