# Local-Only Release Setup

DELTREE releases are intended to be built, signed, notarized, and published from a designated maintainer Mac. Do not put Apple Developer credentials, App Store Connect `.p8` keys, Sparkle private keys, `.p12` files, or passwords in GitHub secrets unless the project intentionally moves back to hosted release signing.

## What App Store Connect Is Used For

This app is distributed outside the Mac App Store. App Store Connect is only used to create an API key for Apple notarization.

Do not create a Mac App Store app record for DELTREE unless the distribution plan changes. Do not upload builds to App Store Connect, enable TestFlight, fill store metadata, configure pricing, create in-app purchases, or submit the app for App Review.

## App Store Connect Steps

1. Sign in to App Store Connect.
2. Open **Users and Access**.
3. Open **Integrations**.
4. Select **App Store Connect API**.
5. If **Request Access** appears, the Account Holder should request access and accept the terms.
6. Open **Team Keys**.
7. Click **Generate API Key** or the add button.
8. Name it `DELTREE Notarization Local`.
9. Choose the lowest role available for notarization. Start with `Developer`; if `Scripts/setup-local-release-secrets.sh` fails validation, revoke that key and create a replacement with `Admin`.
10. Click **Generate**.
11. Copy the **Key ID** and **Issuer ID**.
12. Download the `.p8` private key immediately. Apple only allows one download.
13. Move it to `~/.config/deltree/private/AuthKey_<KEY_ID>.p8`.
14. Run `chmod 600 ~/.config/deltree/private/AuthKey_<KEY_ID>.p8`.

## Apple Developer Steps

Developer ID certificates are managed through the Apple Developer account or Xcode, not through a Mac App Store listing.

1. Confirm the Apple Developer Program membership is active.
2. Create or download a **Developer ID Application** certificate.
3. Install the certificate and its private key in this Mac's login keychain.
4. Confirm the identity is visible:

```sh
security find-identity -v -p codesigning | grep "Developer ID Application"
```

## Sparkle Key Steps

Sparkle update signing should use macOS Keychain. Resolve Xcode packages once so Sparkle's command-line tools exist, then generate the key:

```sh
xcodebuild -resolvePackageDependencies -project DELTREE.xcodeproj -scheme DELTREE
build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
```

Copy the printed public EdDSA key into the local release env file as `DELTREE_SPARKLE_PUBLIC_ED_KEY`. The private Sparkle key remains in Keychain.

## Local Env File

Create the private local folder and env file:

```sh
mkdir -p ~/.config/deltree/private
Scripts/setup-local-release-secrets.sh --print-template > ~/.config/deltree/release.env
chmod 600 ~/.config/deltree/release.env
```

Edit `~/.config/deltree/release.env` and fill in the real values:

```sh
export DELTREE_TEAM_ID="TEAMID1234"
export DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name or Company (TEAMID1234)"
export DELTREE_NOTARY_PROFILE="deltree-notary-profile"
export DELTREE_APP_STORE_CONNECT_KEY_ID="ABC123DEFG"
export DELTREE_APP_STORE_CONNECT_ISSUER_ID="00000000-0000-0000-0000-000000000000"
export DELTREE_APP_STORE_CONNECT_API_KEY_FILE="$HOME/.config/deltree/private/AuthKey_ABC123DEFG.p8"
export DELTREE_SPARKLE_PUBLIC_ED_KEY="YOUR_SPARKLE_PUBLIC_ED25519_KEY"
export DELTREE_SPARKLE_FEED_URL="https://github.com/hazennik/DELTREE/releases/latest/download/appcast.xml"
```

Store the notarization credentials in Keychain:

```sh
Scripts/setup-local-release-secrets.sh
```

## Release From This Mac

From a clean `main` checkout:

```sh
git pull --ff-only origin main
git tag v1.0.0-rc.1
git push origin v1.0.0-rc.1
Scripts/release-local.sh v1.0.0-rc.1 --repo hazennik/DELTREE --draft
```

Review the draft release assets, complete release QA, then publish the GitHub Release.

For a non-draft release:

```sh
Scripts/release-local.sh v1.0.0 --repo hazennik/DELTREE
```

Artifacts published to GitHub Releases:

- `DELTREE.zip`
- `DELTREE.zip.sha256`
- `DELTREE.dSYM.zip`
- `DELTREE.dSYM.zip.sha256`
- `appcast.xml`

## Credential Rules

- Keep Apple and Sparkle private material outside the repo.
- Keep `~/.config/deltree/release.env` at `chmod 600`.
- Keep the Developer ID certificate/private key in Keychain.
- Keep the Sparkle private update key in Keychain.
- Use the App Store Connect `.p8` key only to store a notarytool profile in Keychain.
- Revoke and replace the App Store Connect API key if the `.p8` file is exposed or lost.
- Contact Apple Developer Support about revocation if the Developer ID private key is compromised.
