# Roadmap

## Public Open Source Readiness

- Publish signed and notarized GitHub Releases.
- Publish Sparkle appcast artifacts alongside releases.
- Add a Homebrew cask after the first public signed release.
- Keep screenshots current and add short workflow GIFs after release-candidate builds.
- Keep CI green for Xcode build/test/analyze, SwiftPM core tests, lint, scripts, and package dry runs.

## Product

- Add richer attribution for Codex task workspaces and Xcode result bundles.
- Add exportable diagnostic bundles with path redaction.
- Add optional cleanup scheduling reminders without automatic deletion.
- Add clearer first-run permission explanations for developer folders.

## Engineering

- Continue extracting pure scanner, planner, and model logic into `DELTREECore`.
- Add benchmark fixtures for large directory scans.
- Add package-script tests for notarization and Sparkle appcast paths.
- Add localization once public issue feedback stabilizes copy.
