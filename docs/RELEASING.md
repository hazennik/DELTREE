# Releasing

DELTREE is intended for Developer ID distribution outside the Mac App Store.

## Prerequisites

- Developer ID Application certificate installed locally.
- Apple Developer Team ID.
- Notarization keychain profile configured for `xcrun notarytool`.
- Sparkle EdDSA keys and a real appcast URL before public updates are enabled.

## Build And Test

```sh
xcodebuild test -scheme DELTREE -project DELTREE.xcodeproj -destination 'platform=macOS'
```

## Package

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
Scripts/package-release.sh
```

The packaging script builds a signed archive and zip. It does not invent credentials, notarization profiles, Sparkle keys, or feed URLs.

## Release Checklist

- Confirm cleanup safety tests pass.
- Confirm manual scan on a machine with Xcode installed.
- Confirm CLI dry run.
- Confirm no production hard-delete path.
- Sign and notarize.
- Update Sparkle appcast only after keys and feed URLs are configured.

