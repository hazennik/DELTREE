# Icon Pipeline

DELTREE uses a repeatable developer-folder icon pipeline for the app icon and README previews.

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
- `DELTREE/Assets.xcassets/ClassicAppIcon.imageset/*.png`
- `DELTREE/Assets.xcassets/ClassicAppIcon.imageset/Contents.json`
- `docs/assets/deltree-icon-preview.png`
- `docs/assets/deltree-icon-classic-preview.png`

Source images:

- `docs/assets/deltree-icon-source.png`
- `docs/assets/deltree-icon-classic-source.png`

The modern icon should read as a polished macOS developer utility: blue rounded tile, white folder, and a minimal blue `>_` prompt mark. The Classic icon should preserve the same folder and prompt silhouette with a black surface and cyan terminal glow. Avoid app-name text and tiny details that collapse at small sizes.
