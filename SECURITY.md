# Security

DELTREE is local-only and does not provide a network service.

## Reporting

While this repository is private, report security issues directly to the repository owner instead of opening a public issue.

Before public launch, enable GitHub private vulnerability reporting or add a monitored security contact. Security reports should not include public issue details until a fix is available.

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
