# Homebrew Cask Plan

Homebrew Cask distribution should start after DELTREE has repeatable signed and notarized GitHub Releases.

Build Homebrew-owned artifacts with:

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
DELTREE_NOTARY_PROFILE="deltree-notary-profile" \
Scripts/package-release.sh --notarize --distribution homebrew
```

The Homebrew channel writes `DELTREEDistributionChannel=homebrew` into the app. `DistributionChannel.allowsSparkleUpdates` is false for Homebrew builds so future Sparkle update UI can defer to `brew upgrade`.

## Required Inputs

- Public `DELTREE.zip` release URL.
- SHA-256 checksum for the release zip.
- Stable bundle identifier: `com.Infrallabs.DELTREE`.
- Minimum macOS version.
- Sparkle appcast URL if Homebrew should include update metadata.

## Draft Cask Shape

```ruby
cask "deltree" do
  version "1.0.0"
  sha256 "<release zip sha256>"

  url "https://github.com/hazennik/DELTREE/releases/download/v#{version}/DELTREE.zip"
  name "DELTREE"
  desc "Local-only macOS utility for safely managing Codex and Xcode storage"
  homepage "https://github.com/hazennik/DELTREE"

  depends_on macos: ">= :sonoma"

  app "DELTREE.app"

  zap trash: [
    "~/Library/Application Support/DELTREE",
    "~/Library/Preferences/com.Infrallabs.DELTREE.plist",
  ]
end
```

Do not publish a cask until the release workflow signs, notarizes, staples, and verifies every attached app artifact.
