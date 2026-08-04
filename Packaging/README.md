# DELTREE Packaging

DELTREE is intended for Developer ID distribution outside the Mac App Store because it scans Xcode and Codex developer paths and moves approved items to Trash.

Required local configuration:

- `DELTREE_DEVELOPER_ID_APPLICATION`: Developer ID Application signing identity.
- `DELTREE_TEAM_ID`: Apple Developer Team ID.
- `DELTREE_NOTARY_PROFILE`: notarization keychain profile for `xcrun notarytool`.
- `DELTREE_RELEASE_ZIP_URL`: public URL for the final zip.
- `DELTREE_SPARKLE_SIGNATURE`: Sparkle EdDSA signature for the final zip.

The package script builds a signed archive and zip, optionally submits it for notarization, and staples the app before recreating the zip.

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
DELTREE_NOTARY_PROFILE="deltree-notary-profile" \
Scripts/package-release.sh --notarize
```

Generate the Sparkle appcast after signing the final zip with Sparkle's `sign_update` tool:

```sh
DELTREE_RELEASE_ZIP_URL="https://github.com/hazennik/DELTREE/releases/download/v1.0/DELTREE.zip" \
DELTREE_SPARKLE_SIGNATURE="..." \
Scripts/generate-appcast.sh
```

CI can validate the release command path without secrets:

```sh
make package-check
make appcast-check
```

The scripts do not invent production credentials, notarization profiles, Sparkle keys, or update-feed URLs outside explicit dry runs.
