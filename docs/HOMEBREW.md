# Homebrew Cask Plan

Homebrew Cask distribution should start after DELTREE has repeatable signed and notarized GitHub Releases.

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
