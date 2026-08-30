# Release QA

This checklist must pass before DELTREE is called public GA.

## Release Candidate

Use `v1.0.0-rc.1` for the first full release candidate.

Required CI proof:

- The selected release path completes with real Developer ID signing, notarization, and Sparkle credentials. For the default local path, `Scripts/release-local.sh v1.0.0-rc.1 --repo hazennik/DELTREE --draft` succeeds.
- The prerelease build uses a stable prerelease-channel appcast URL; GitHub's `/releases/latest/` redirect is reserved for stable releases because it excludes prereleases.
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
- Confirm an available CoreSimulator device is never offered direct filesystem or Trash cleanup.
- Confirm simulator delete/erase preflight calls the action irreversible and does not claim that all cleanup is recoverable.
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

- Run `make export-screenshots` after the release-candidate build and review every PNG under `docs/assets/screenshots`.
- Confirm the README uses the Modern dashboard and menu-bar dropdown as the main set, with Classic/retro screenshots as the smaller secondary set.
- Confirm `docs/assets/screenshots/social-preview.png` is current before updating GitHub repository social preview settings.
- Keep the retro command-prompt identity in repo assets, not at the expense of macOS-native UI clarity.
