# DELTREE Packaging

DELTREE is intended for Developer ID distribution outside the Mac App Store because it scans Xcode and Codex developer paths and moves approved items to Trash.

Required local configuration:

- `DELTREE_DEVELOPER_ID_APPLICATION`: Developer ID Application signing identity.
- `DELTREE_TEAM_ID`: Apple Developer Team ID.
- A notarization keychain profile for `xcrun notarytool`.
- Sparkle EdDSA keys and a real appcast URL before enabling public updates.

The package script builds a signed archive and zip. It does not invent credentials, notarization profiles, Sparkle keys, or update-feed URLs.
