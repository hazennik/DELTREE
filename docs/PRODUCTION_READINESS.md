# Production Readiness

DELTREE's source repository can be public before signed app downloads exist. The app should be called public GA only after both engineering guardrails and release-distribution gates pass.

## Runtime Guardrails

- Cleanup execution must fail closed. Each action is revalidated immediately before execution for active, pinned, ignored, blocked-domain, unsafe-classification, missing-path, open-file, and simulator-state changes.
- Regular file and folder cleanup must use Trash. Permanent regular-file deletion is not part of v1 production behavior.
- Simulator cleanup must use only explicit `simctl delete` or `simctl erase` actions, identify their irreversible effects before confirmation, and skip booted devices or devices whose availability changed.
- Scanning must stay bounded to known developer roots unless the user opts into additional roots.
- Large filesystem walks must be cancellable, and default file-size scans must use the production entry budget.
- Codex thread/session previews must be bounded so unusually large logs do not become unbounded memory reads.
- External process calls must have timeouts so `ps`, `lsof`, and `simctl` cannot hang the app indefinitely.
- Persistence writes must surface errors to the user instead of silently dropping failed scan, cleanup, or override history.
- Menu-triggered cleanup must respect notify-only mode and must never bypass confirmation thresholds.

## Required Local Checks

Run these before a release-candidate build:

```sh
make lint
make test
swift test
make analyze
make script-test
make docs-check
make workflow-check
make repository-check
make package-check
make appcast-check
make spark-sign-check
make cli-dry-run
make build
```

Run UI tests separately on a trusted local Mac:

```sh
make ui-test
```

`make ui-test` is the release-gate launch smoke test. It builds the locally signed app, verifies the menu-bar `LSUIElement` configuration, launches with initial scanning disabled, and exits through `DELTREE_EXIT_AFTER_LAUNCH=1`.
Run `make xcode-ui-test` when investigating the Xcode UI automation runner itself; that target is not the public release gate because Xcode worker materialization can hang before tests execute.

## Manual Smoke Tests

- Launch the app from a clean build and confirm the menu-bar item appears without an initial full-disk crawl.
- Grant any macOS file-access prompts that appear, then rerun the scan.
- Confirm cancellation remains responsive during a scan with large Codex and Xcode folders.
- Confirm notify-only mode suppresses menu cleanup actions.
- Confirm the cleanup preflight shows high-impact confirmation text when the configured byte threshold is exceeded.
- Move a safe test fixture to Trash through the normal confirmation flow.
- Confirm open-file candidates are blocked by the final execution revalidation.
- Confirm booted simulator devices are never deleted or erased.
- Relaunch the app and confirm persisted settings, history, and manual overrides load correctly.
- Run `Tools/deltree --dry-run --json` and confirm the CLI does not mutate local storage.
- Run `make export-screenshots` after any visible UI change and confirm the modern dashboard/menu screenshots and smaller Classic screenshots are not blank or clipped.

## Public GA Gates

- [x] Complete a real Developer ID signed and Apple-notarized package run.
- [x] Publish RC.1 with `DELTREE.zip`, checksum files, dSYM archive, and a signed Sparkle appcast.
- [x] Protect the RC.1 tag and publish its attached assets as an immutable GitHub prerelease.
- [ ] Download, install, launch, and validate RC.1 on a Mac that has not built DELTREE locally.
- [ ] Publish a second signed candidate and complete a Sparkle update smoke test from RC.1 to RC.2.
- [ ] Review README media and replace screenshots or GIFs if clean-machine QA reveals visible differences.
- [ ] Complete the full [Release QA](RELEASE_QA.md) checklist before calling the app public GA.
