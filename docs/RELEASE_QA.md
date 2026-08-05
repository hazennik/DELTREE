# Release QA

This checklist must pass before DELTREE is called public GA.

## Release Candidate

Use `v1.0.0-rc.1` for the first full private release candidate.

Required CI proof:

- Release workflow completes with real Developer ID, notarization, and Sparkle secrets.
- The checks in [Production Readiness](PRODUCTION_READINESS.md) pass on the release-candidate branch.
- GitHub Release contains `DELTREE.zip`, `DELTREE.zip.sha256`, `DELTREE.dSYM.zip`, `DELTREE.dSYM.zip.sha256`, and `appcast.xml`.
- `Scripts/check-release-assets.sh v1.0.0-rc.1 --repo hazennik/DELTREE` passes after publishing.
- Sparkle appcast points to the published `DELTREE.zip` and uses the final zip length/signature.

## Clean-Machine Install

Run on a Mac that has not built DELTREE locally.

- Download `DELTREE.zip` from the GitHub Release.
- Extract with Archive Utility or `ditto -x -k DELTREE.zip .`.
- Confirm Gatekeeper launch succeeds without bypassing security prompts.
- Confirm `codesign --verify --deep --strict --verbose=2 DELTREE.app` succeeds.
- Confirm `xcrun stapler validate DELTREE.app` succeeds.
- Launch DELTREE, run a scan, and confirm no full-disk crawl occurs.
- Move at least one safe test fixture to Trash through the cleanup confirmation flow.
- Relaunch DELTREE and confirm history/settings remain stable.
- Uninstall DELTREE, reinstall from the same release zip, and relaunch.
- Run `Tools/deltree diagnose --json` and confirm the output is redacted.

## Sparkle Smoke Test

- Install the previous signed Developer ID build in `/Applications`.
- Publish the next RC or GA appcast.
- Use `Check for Updates...`.
- Confirm Sparkle sees the update, shows release notes, downloads the zip, validates the EdDSA signature, and relaunches the updated app.
- Confirm Homebrew-channel builds do not show Sparkle update UI.

## Public Media

- Capture polished real app screenshots from the clean-machine RC build.
- Replace temporary README media with optimized PNG/GIF assets before public GA.
- Keep the retro command-prompt identity in repo assets, not at the expense of macOS-native UI clarity.
