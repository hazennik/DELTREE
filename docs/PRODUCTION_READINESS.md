# Production Readiness

DELTREE can be called production ready only after both engineering guardrails and release-distribution gates pass. Until then, the repository status remains production-candidate/private beta.

## Runtime Guardrails

- Cleanup execution must fail closed. Each action is revalidated immediately before execution for active, pinned, ignored, blocked-domain, unsafe-classification, missing-path, open-file, and simulator-state changes.
- File cleanup must use Trash. Permanent deletion is not part of v1 production behavior.
- Simulator cleanup must use only explicit `simctl delete` or `simctl erase` actions, and booted or now-available devices must be skipped.
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

- Complete a real Developer ID signed and notarized package run.
- Staple and validate the app on a clean Mac that has not built DELTREE locally.
- Publish a release candidate with `DELTREE.zip`, checksum files, dSYM archive, and Sparkle appcast assets.
- Complete a Sparkle update smoke test from one signed build to the next.
- Replace temporary README media with polished screenshots or GIFs from the clean-machine release-candidate build.
- Complete the full [Release QA](RELEASE_QA.md) checklist before calling the app public GA.
