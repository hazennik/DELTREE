# Issue Triage

This guide keeps public DELTREE issues consistent once the repository is open source.

## First Pass

Apply `needs-triage` to new issues until a maintainer has reproduced, classified, or intentionally declined them. For bug reports, keep `needs-diagnostics` until the issue includes enough redacted diagnostic context to investigate.

Prioritize safety first. Anything involving data loss, incorrect cleanup eligibility, privacy exposure, or misleading cleanup confirmation should get `data-safety` and maintainer review before cosmetic or convenience work.

## Severity

P0 issues block release and should be handled immediately: confirmed data loss, cleanup outside the reviewed plan, privacy leaks, compromised release assets, or broken signing/notarization.

P1 issues block a public production release when reproducible: app fails to launch, scans cannot complete on supported macOS versions, crashes in normal workflows, or release update channels are invalid.

P2 issues should be fixed before the next planned release: incorrect category attribution, confusing cleanup skips, degraded performance on common developer folders, or missing diagnostics.

P3 issues are routine improvements: copy, layout polish, docs gaps, contributor workflow improvements, and feature requests without safety impact.

## Labels

- `bug`: Reproducible product defect.
- `needs-triage`: Maintainer has not classified the issue yet.
- `needs-diagnostics`: Needs redacted `Tools/deltree diagnose --json` output.
- `data-safety`: Cleanup safety, privacy, or data-loss risk.
- `scanner`: Storage discovery, attribution, or sizing behavior.
- `cleanup`: Cleanup planning, confirmation, execution, or skipped items.
- `crash`: Crash log, symbolication, or launch crash.
- `performance`: Speed, memory, battery, or responsiveness.
- `release`: Packaging, signing, notarization, Sparkle, appcast, or Homebrew.
- `documentation`: README, docs, examples, screenshots, or contributor guidance.
- `ui`: Dashboard, menu-bar panel, settings, screenshots, accessibility, or visual polish.
- `enhancement`: New capability or behavior improvement.
- `dependencies`: Dependency update.
- `swift`: Swift or Xcode toolchain change.
- `github-actions`: GitHub Actions workflow change.
- `question`: Support request or discussion that is not yet a bug or feature request.

## Diagnostic Requests

Ask for the minimum useful information:

- macOS version.
- DELTREE version and install source.
- Exact reproduction steps.
- Redacted `Tools/deltree diagnose --json` output.
- Screenshot only when it does not reveal private local paths.

Do not ask users to post raw path inventories publicly. Move private logs to a private maintainer channel only when necessary and only after the user agrees.

## Closing Issues

Close duplicates with a link to the canonical issue. Close unreproducible reports only after requesting diagnostics and leaving enough time for a response. Convert feature requests into implementation issues when the user problem and acceptance criteria are clear.
