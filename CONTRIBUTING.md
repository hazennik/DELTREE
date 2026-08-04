# Contributing

This repository is private while DELTREE is still taking shape. Contributions should still follow the same bar as a public project.

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
