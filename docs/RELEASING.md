# Releasing

DELTREE is intended for Developer ID distribution outside the Mac App Store.

## Prerequisites

- Developer ID Application certificate installed locally.
- Apple Developer Team ID.
- Notarization keychain profile configured for `xcrun notarytool`.
- Sparkle EdDSA keys and a real appcast URL before public updates are enabled.
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
Scripts/package-release.sh --notarize
```

The packaging script builds a signed archive and zip, submits the zip to Apple notarization when `--notarize` is present, staples the app, and recreates the zip.

CI and pull requests use dry runs to validate the command path without real credentials:

```sh
make package-check
make appcast-check
```

## Appcast

Generate the Sparkle EdDSA signature from the final notarized zip with Sparkle's `sign_update` tool, then generate the appcast:

```sh
DELTREE_RELEASE_VERSION="1.0" \
DELTREE_RELEASE_BUILD="1" \
DELTREE_RELEASE_ZIP_URL="https://github.com/hazennik/DELTREE/releases/download/v1.0/DELTREE.zip" \
DELTREE_SPARKLE_SIGNATURE="..." \
Scripts/generate-appcast.sh
```

The appcast is written to `build/export/appcast.xml` by default.

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
- `DELTREE_SPARKLE_SIGNATURE`

Set `DELTREE_RELEASE_ZIP_URL` as a repository variable if release assets are hosted somewhere other than GitHub Releases.

## Homebrew

Homebrew Cask distribution should wait until signed, notarized GitHub Releases and Sparkle appcasts are stable. The cask will need the release zip URL, SHA-256 checksum, bundle identifier, and uninstall/zap paths.

## Release Checklist

- Confirm cleanup safety tests pass.
- Confirm manual scan on a machine with Xcode installed.
- Confirm CLI dry run.
- Confirm no production hard-delete path.
- Confirm `DELTREE.xcodeproj` does not contain a personal hardcoded Team ID.
- Sign and notarize with Developer ID.
- Generate Sparkle appcast only after signing the final zip.
- Attach `DELTREE.zip` and `appcast.xml` to the GitHub Release.
