# DELTREE Vision

DELTREE helps developers understand and safely reclaim local storage created by Codex-driven Apple-platform development.

The project should remain:

- Local-first: scan results, cleanup history, and attribution stay on the Mac.
- Conservative: cleanup is explicit, reversible through Trash where possible, and never a hidden background action.
- Developer-focused: Codex, Xcode, simulator, XCTest, SwiftPM, and archive storage are explained in terms working engineers can act on.
- Auditable: safety policy, release process, and privacy behavior are documented well enough for open-source review.

## Product Direction

- Make disk growth attributable to tools, projects, and Codex tasks where local metadata allows.
- Keep the menu bar quiet and make deeper review available in the dashboard.
- Prefer bounded, known-root scanning over broad filesystem crawling.
- Keep cleanup plans inspectable before execution.
- Build distribution through signed, notarized releases with Sparkle updates and reproducible release notes.
