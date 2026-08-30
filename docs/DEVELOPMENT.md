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

## Stable Development Signing

`make build` intentionally creates the unsigned, CI-equivalent build in the stable `build/DerivedData` path. macOS identifies that build with an ad hoc signature tied to the current binary, so privacy grants can be requested again after the executable changes.

For repeated permission testing, build with your own Apple Development team:

```sh
DELTREE_DEVELOPMENT_SIGNING_IDENTITY="APPLE_DEVELOPMENT_CERTIFICATE_SHA1" make signed-dev-build
open build/DerivedData/Build/Products/Debug/DELTREE.app
```

Use the SHA-1 fingerprint of a local Apple Development certificate shown by `security find-identity -v -p codesigning`. Keep `DELTREE_DEVELOPMENT_SIGNING_IDENTITY` and `DELTREE_DEVELOPMENT_BUNDLE_IDENTIFIER` stable between rebuilds. The target verifies that the result has an Apple-backed designated requirement and team identifier without printing or committing the local identity. Do not add a personal Team ID or certificate fingerprint to the project file.

Full Disk Access is a user-controlled macOS privacy decision, not an entitlement DELTREE can declare. The app intentionally has no Full Disk Access entitlement because no such public entitlement grants it. See [Permissions & Troubleshooting](PERMISSIONS.md).

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
- Do not add permanent regular-file delete paths; simulator actions must stay behind explicit, accurately worded `simctl` confirmation.
- Keep scanners bounded to known roots unless the user opts into custom roots.
- Prefer service protocols for filesystem, process, simctl, Trash, and persistence behavior.
- Keep UI state testable through descriptors and view models.
- Add tests for safety policy changes and view-facing filtering, selection, or label logic.
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
DELTREE_DEVELOPMENT_SIGNING_IDENTITY="APPLE_DEVELOPMENT_CERTIFICATE_SHA1" make signed-dev-build
make export-screenshots
Tools/deltree --dry-run --json
rg "removeItem|trashItem|simctl" DELTREE DELTREETests Tools Scripts
```
