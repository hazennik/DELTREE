# DELTREE Packaging

DELTREE is intended for Developer ID distribution outside the Mac App Store because it scans Xcode and Codex developer paths and moves approved items to Trash.

Required local configuration:

- `DELTREE_DEVELOPER_ID_APPLICATION`: Developer ID Application signing identity.
- `DELTREE_TEAM_ID`: Apple Developer Team ID.
- `DELTREE_NOTARY_PROFILE`: notarization keychain profile for `xcrun notarytool`.
- `DELTREE_RELEASE_ZIP_URL`: public URL for the final zip.
- `DELTREE_SPARKLE_PRIVATE_KEY_FILE` or `DELTREE_SPARKLE_PRIVATE_KEY_BASE64`: Sparkle EdDSA private key material used only by `Scripts/sign-sparkle-update.sh`.
- `DELTREE_SPARKLE_PUBLIC_ED_KEY`: Sparkle public key embedded in the app Info.plist.

Use [Local-Only Release Setup](../docs/LOCAL_RELEASE.md) for the recommended Keychain-backed release configuration. `Scripts/release-local.sh` runs the full local release path from a clean tag.

The package script builds a signed archive and zip, verifies the bundled DELTREE and Sparkle license notices, optionally submits the app for notarization, staples it before recreating the zip, packages matching dSYMs, and writes SHA-256 checksum files.

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
DELTREE_NOTARY_PROFILE="deltree-notary-profile" \
Scripts/package-release.sh --notarize
```

Generate the Sparkle appcast after signing the final zip with Sparkle's `sign_update` tool:

```sh
Scripts/sign-sparkle-update.sh --zip build/export/DELTREE.zip --env-output build/release/sparkle.env
source build/release/sparkle.env

DELTREE_RELEASE_ZIP_URL="https://github.com/hazennik/DELTREE/releases/download/v1.0/DELTREE.zip" \
Scripts/generate-appcast.sh
```

CI can validate the release command path without secrets:

```sh
make package-check
make appcast-check
make spark-sign-check
```

The scripts do not invent production credentials, notarization profiles, Sparkle keys, or update-feed URLs outside explicit dry runs.
