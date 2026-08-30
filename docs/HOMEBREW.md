# Homebrew Cask Plan

Homebrew Cask distribution should start after DELTREE has repeatable signed and notarized GitHub Releases.

Build Homebrew-owned artifacts with:

```sh
DELTREE_DEVELOPER_ID_APPLICATION="Developer ID Application: Example" \
DELTREE_TEAM_ID="TEAMID1234" \
DELTREE_NOTARY_PROFILE="deltree-notary-profile" \
Scripts/package-release.sh --notarize --distribution homebrew
```

The Homebrew channel writes `DELTREEDistributionChannel=homebrew` into the app and produces `build/export/DELTREE-homebrew.zip`. `DistributionChannel.allowsSparkleUpdates` is false for Homebrew builds so Sparkle update UI defers to `brew upgrade`.

## Required Inputs

- Public `DELTREE-homebrew.zip` release URL.
- SHA-256 checksum for the release zip.
- Stable bundle identifier: `com.Infrallabs.DELTREE`.
- Minimum macOS version.
- Sparkle appcast URL if Homebrew should include update metadata.

Generate the cask after a stable GA release:

```sh
Scripts/generate-homebrew-cask.sh \
  --version 1.0.0 \
  --sha256 "$(shasum -a 256 build/export/DELTREE-homebrew.zip | awk '{print $1}')" \
  --output Casks/deltree.rb
```

## Draft Cask Shape

```ruby
cask "deltree" do
  version "1.0.0"
  sha256 "<release zip sha256>"

  url "https://github.com/hazennik/DELTREE/releases/download/v#{version}/DELTREE-homebrew.zip"
  name "DELTREE"
  desc "Privacy-first macOS utility for safely managing Codex and Xcode storage"
  homepage "https://github.com/hazennik/DELTREE"

  depends_on macos: ">= :sonoma"

  app "DELTREE.app"

  zap trash: [
    "~/Library/Application Support/DELTREE",
    "~/Library/Preferences/com.Infrallabs.DELTREE.plist",
  ]
end
```

Do not publish a cask until the release workflow signs, notarizes, staples, and verifies every attached app artifact. Do not point the cask at `DELTREE.zip`; that artifact is Sparkle-enabled for direct Developer ID installs.

Validate in the tap before opening or merging the cask update:

```sh
HOMEBREW_NO_INSTALL_FROM_API=1 brew install --cask deltree
brew uninstall --cask deltree
brew audit --new --cask deltree
brew style --fix --cask deltree
```
