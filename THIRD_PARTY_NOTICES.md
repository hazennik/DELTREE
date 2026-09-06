# Third-Party Notices

## CodexBar

DELTREE intentionally follows selected product and architecture patterns from CodexBar by Peter Steinberger:

- menu-bar status item pattern
- testable menu descriptor concept
- bounded local storage probing
- storage breakdown presentation
- async refresh throttling/fingerprinting principles
- local Codex session attribution concepts
- launch-at-login service state handling
- downloaded-update install-and-relaunch handling

No CodexBar source file is vendored wholesale in this repository. The two lifecycle patterns above adapt small portions of CodexBar's MIT-licensed implementation.

CodexBar repository: https://github.com/steipete/CodexBar

## Sparkle

DELTREE uses Sparkle 2 for Developer ID app updates. Sparkle is distributed under the MIT license.

Sparkle repository: https://github.com/sparkle-project/Sparkle

The complete Sparkle and bundled-component license text is kept in
[`DELTREE/Resources/Sparkle-LICENSE.txt`](DELTREE/Resources/Sparkle-LICENSE.txt) and is included in distributed app bundles.
