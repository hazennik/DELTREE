# Release QA

This checklist must pass before DELTREE is called public GA.

## Release Candidate

RC.1 and RC.2 established the signed release pipeline. Use the most recent published candidate as the installed baseline and publish a newer candidate from current `main` as the update target. Public GA requires clean-machine install evidence and a complete update between those two immutable candidates.

Required CI proof:

- The selected release path completes with real Developer ID signing, notarization, and Sparkle credentials. For the default local path, `Scripts/release-local.sh <new-tag> --repo hazennik/DELTREE --draft` succeeds.
- The prerelease build uses a stable prerelease-channel appcast URL; GitHub's `/releases/latest/` redirect is reserved for stable releases because it excludes prereleases.
- The checks in [Production Readiness](PRODUCTION_READINESS.md) pass on the release-candidate branch.
- GitHub Release contains `DELTREE.zip`, `DELTREE.zip.sha256`, `DELTREE.dSYM.zip`, `DELTREE.dSYM.zip.sha256`, and `appcast.xml`.
- `Scripts/check-release-assets.sh <new-tag> --repo hazennik/DELTREE` passes after publishing.
- Sparkle appcast points to the published `DELTREE.zip` and uses the final zip length/signature.

## Clean-Machine Install

Run on a Mac that has not built DELTREE locally.

- Download `DELTREE.zip` from the GitHub Release.
- Extract with Archive Utility or `ditto -x -k DELTREE.zip .`.
- Confirm Gatekeeper launch succeeds without bypassing security prompts.
- Confirm `codesign --verify --deep --strict --verbose=2 DELTREE.app` succeeds.
- Confirm `xcrun stapler validate DELTREE.app` succeeds.
- Launch DELTREE, run a scan, and confirm no full-disk crawl occurs.
- Confirm first launch and background scans do not request Documents access while **Scan ~/Documents/Codex** is off.
- Enable **Scan ~/Documents/Codex**, choose **Scan Now**, respond to the access prompt, and confirm the same decision is not requested repeatedly.
- Move at least one safe test fixture to Trash through the cleanup confirmation flow.
- Modify or replace a planned test fixture before confirmation and confirm DELTREE skips it with a specific Cleanup History reason.
- Confirm an available CoreSimulator device is never offered direct filesystem or Trash cleanup.
- Confirm simulator delete/erase preflight calls the action irreversible and does not claim that all cleanup is recoverable.
- Relaunch DELTREE and confirm history/settings remain stable.
- Test **Launch DELTREE at login**, automatic update preferences, and both update commands in Settings.
- Repeat install, launch, scan, and non-destructive UI checks on both Apple Silicon and Intel hardware or equivalent clean hosted runners.
- Uninstall DELTREE, reinstall from the same release zip, and relaunch.
- Run `Tools/deltree diagnose --json` and confirm the output is redacted.

## Sparkle Smoke Test

- Install the previous signed Developer ID candidate in `/Applications`.
- Publish the new candidate with the same Developer ID identity and Sparkle public key.
- Run `Scripts/stage-prerelease-feed.sh <new-tag> --repo hazennik/DELTREE`, then merge the staged `docs/prerelease/appcast.xml` through a protected pull request.
- Confirm `https://hazennik.github.io/DELTREE/prerelease/appcast.xml` serves the new candidate before checking for updates from the installed baseline.
- Use `Check for Updates...`.
- Confirm Sparkle sees the new candidate, shows release notes, downloads the zip, and validates the EdDSA signature.
- Confirm `Install Update and Relaunch` appears in both Settings and the menu-bar mini menu, then use it.
- Confirm the relaunched app reports the new candidate's version and build number.
- Confirm Homebrew-channel builds do not show Sparkle update UI.

## Public Media

- Run `make export-screenshots` after the release-candidate build and review every PNG under `docs/assets/screenshots`.
- Confirm the README uses the Modern dashboard and menu-bar dropdown as the main set, with Classic/retro screenshots as the smaller secondary set.
- Confirm `docs/assets/screenshots/social-preview.png` is current before updating GitHub repository social preview settings.
- Keep the retro command-prompt identity in repo assets, not at the expense of macOS-native UI clarity.
