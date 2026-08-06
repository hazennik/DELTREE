# Development

## Setup

Clone the repository and open the Xcode project:

```sh
open DELTREE.xcodeproj
```

Install optional formatting and linting tools:

```sh
brew install swiftformat swiftlint
```

Run the standard checks:

```sh
make build
make test
make swift-test
make analyze
make workflow-check
make docs-check
make icon-check
make script-test
make cli-dry-run
make package-check
make appcast-check
make spark-sign-check
```

`make test` skips `DELTREEUITests` because macOS UI-test runner apps can require local signing trust. Use `make ui-test` to validate signed menu-bar launch behavior on a trusted local machine. It builds the app, verifies `LSUIElement`, launches with initial scanning disabled, and exits through `DELTREE_EXIT_AFTER_LAUNCH=1`.
`make xcode-ui-test` keeps the legacy Xcode UI automation target available for deeper local debugging, but it can hang in Xcode's worker materialization phase on some macOS/Xcode combinations.
`make package-check` performs dry-run package validation for both Developer ID and Homebrew distribution channels.

Regenerate README and social-preview screenshots from the app's real SwiftUI views:

```sh
make export-screenshots
```

## Project Layout

- `DELTREE/App`: app lifecycle, status item, menu rendering
- `DELTREE/Models`: domain types and value models
- `DELTREE/Services`: scanners, attribution, cleanup, persistence adapters
- `DELTREE/ViewModels`: dashboard and preview view models
- `DELTREE/Views`: SwiftUI dashboard, settings, tables, inspectors
- `Package.swift`: SwiftPM `DELTREECore` target for non-UI model and service tests
- `Tests/DELTREECoreTests`: SwiftPM tests runnable without Xcode project loading
- `DELTREETests`: unit and integration-style tests
- `DELTREEUITests`: LSUIElement launch coverage
- `Tools`: bundled CLI helper
- `Scripts`: install and packaging scripts
- `Packaging`: release packaging notes and update scaffolding

## Engineering Rules

- Keep cleanup conservative.
- Do not add permanent delete paths.
- Keep scanners bounded to known roots unless the user opts into custom roots.
- Prefer service protocols for filesystem, process, simctl, Trash, and persistence behavior.
- Keep UI state testable through descriptors and view models.
- Add tests for safety policy changes.
- Keep signing configuration environment-driven. Use `DELTREE_DEVELOPMENT_TEAM` locally instead of committing a personal Team ID.

## Useful Commands

```sh
git status -sb
make check
make lint
make format
make workflow-check
make docs-check
make icon-check
make script-test
swift test
make ui-test
make export-screenshots
Tools/deltree --dry-run --json
rg "removeItem|trashItem|simctl" DELTREE DELTREETests Tools Scripts
```
