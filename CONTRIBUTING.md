# Contributing

DELTREE welcomes focused bug reports, documentation improvements, tests, and code contributions that preserve its conservative cleanup model.

Before starting a large change, open an issue so maintainers and contributors can align on scope and safety implications.

Agents and agent-assisted contributors should also follow [AGENTS.md](AGENTS.md), especially its cleanup-safety and credential-handling rules.

## Pull Request Expectations

- Keep changes scoped.
- Include tests for scanner, attribution, safety, or cleanup changes.
- Do not weaken cleanup safety rules without updating `docs/SAFETY.md`.
- Run the full macOS test target before requesting review.
- Update docs when behavior changes.

## Local Checks

```sh
make check
Tools/deltree diagnose --json
```

Use [docs/TRIAGE.md](docs/TRIAGE.md) when labeling public issues or deciding whether a report needs private diagnostics.

## Commit Style

Use short imperative commit messages:

```text
Add simulator cleanup preflight
Document release signing requirements
Fix Codex attribution matching
```

## Safety Review Required

Any change touching these areas needs careful review:

- `DefaultSafetyPolicy`
- `DefaultCleanupPlanner`
- `DefaultCleanupExecutor`
- `FileManagerTrashService`
- `LiveSimctlCommandClient`
- domain scanners that mark items safe
