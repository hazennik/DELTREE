# Security

DELTREE is local-only and does not provide a network service.

## Reporting

Report vulnerabilities through [GitHub private vulnerability reporting](https://github.com/hazennik/DELTREE/security/advisories/new).

Do not open a public issue for an unpatched vulnerability or include private paths, Codex transcripts, signing material, or proprietary project data in a report. If private vulnerability reporting is temporarily unavailable, contact the repository owner through a private channel listed on the [maintainer's GitHub profile](https://github.com/hazennik).

Include the affected version or commit, macOS and Xcode versions, impact, reproduction steps, and the minimum redacted diagnostics needed to investigate. Maintainers will acknowledge reports as soon as practical and coordinate disclosure after a fix is available.

## Supported Versions

Security fixes are provided for the latest published release and the current `main` branch. Older prerelease builds may be asked to upgrade before investigation continues.

## Sensitive Areas

Please treat these as security-sensitive:

- cleanup execution
- Trash handling
- simulator delete/erase commands
- filesystem scanning scope
- local process inspection
- Codex task/session metadata parsing
- release signing and notarization
- Sparkle update signing and appcast generation

## Data Handling

DELTREE should not upload paths, scan results, project names, Codex metadata, account data, or cleanup history.

Do not add analytics, crash reporting, network upload, or telemetry without explicit product review and a privacy update. Sparkle update checks are allowed only for Developer ID builds and must use signed update artifacts.
