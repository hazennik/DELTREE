# Icon Pipeline

DELTREE uses a repeatable command-prompt-inspired icon pipeline for the app icon and README preview.

Regenerate assets:

```sh
Scripts/build-icon.sh --write
```

Verify tracked assets are current:

```sh
make icon-check
```

Generated outputs:

- `DELTREE/Assets.xcassets/AppIcon.appiconset/*.png`
- `DELTREE/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `docs/assets/deltree-icon-preview.png`

The icon should read as restrained retro MS-DOS: black terminal face, green prompt, amber accent, and no decorative gradients. Keep the in-app UI native and accessible.
