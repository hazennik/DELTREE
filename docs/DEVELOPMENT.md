# Development

## Setup

Clone the repository and open the Xcode project:

```sh
open DELTREE.xcodeproj
```

Run all tests:

```sh
xcodebuild test -scheme DELTREE -project DELTREE.xcodeproj -destination 'platform=macOS'
```

Run the CLI helper:

```sh
Tools/deltree --dry-run
```

## Project Layout

- `DELTREE/App`: app lifecycle, status item, menu rendering
- `DELTREE/Models`: domain types and value models
- `DELTREE/Services`: scanners, attribution, cleanup, persistence adapters
- `DELTREE/ViewModels`: dashboard and preview view models
- `DELTREE/Views`: SwiftUI dashboard, settings, tables, inspectors
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

## Useful Commands

```sh
git status -sb
xcodebuild test -scheme DELTREE -project DELTREE.xcodeproj -destination 'platform=macOS'
Tools/deltree --dry-run --json
rg "removeItem|trashItem|simctl" DELTREE DELTREETests Tools Scripts
```

