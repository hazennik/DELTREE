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
make script-test
make cli-dry-run
make package-check
make appcast-check
```

`make test` skips `DELTREEUITests` because macOS UI-test runner apps can require local signing trust. Use `make ui-test` when validating launch behavior on a trusted local machine.
`make package-check` performs dry-run package validation for both Developer ID and Homebrew distribution channels.

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
make script-test
swift test
make ui-test
Tools/deltree --dry-run --json
rg "removeItem|trashItem|simctl" DELTREE DELTREETests Tools Scripts
```
