# scripts/

## lib/
Domain-agnostic classes. Know nothing about icon paths or theme structure — only about the formats they handle. Can be reused or tested in isolation.

- `palette.rb` — OKLCH color math; hue-family mapping (circular mean + chroma tiebreak) to find the nearest palette entry
- `svg_tracker.rb` — SVG parsing and manipulation (Nokogiri wrapper); color extraction, replacement, group operations

## core/
Domain-aware orchestration. Knows where icons live, what templates exist, and how the theme is structured. Depends on `lib/`.

- `icon_preprocessor.rb` — batch file processing, CLI argument parsing, versioned output (`-f`, `-d`, `--tag`, `--non-apps`, `--new`)

## autofix/
Non-destructive transforms. Each script creates a new versioned file (`.v2`, `.v3`, …) — the original is never edited. Run `apply_changes.rb` to promote a version to the original.

- `recolor.rb` — remaps icon colors to the nearest palette entry. Use `--non-apps` to recolor all colors instead of only those in `bg`/`art`/`em` groups
- `update_shadows.rb` — replaces the drop shadow group (`#ds`) with the canonical template
- `apply_changes.rb` — promotes `.vN` files back to their originals. Single vN → auto; multiple → prompts. Supports `--dry-run`
- `undo_changes.rb` — deletes all `.vN` files in the target area, leaving only originals. Supports `--dry-run`

### Common flags
All autofix scripts (and `icon_preprocessor` consumers) share:

| Flag | Description |
|---|---|
| `-f <file>` | Single file (filename or path from project root) |
| `-d <dir>` | Directory relative to project root |
| `--tag <name>` | Named output (`icon-name.svg`) — skips version bump and the versioned-file guard |
| `--non-apps` | Recolor all colors in the document, not just `bg`/`art`/`em` groups |
| `--dry-run` | Preview actions without writing files (`apply_changes`, `undo_changes`) |

## v3/
Palette generation and analysis. Output goes to `design/assets/`.

- `gen_palette.rb` — generates `palette.yaml` and `palette-data.js` from REVERSAL_T4 anchors + OKLCH interpolation
- `chroma_analysis.rb` — generates `chroma-analysis.html`: sRGB gamut max, REVERSAL_T4 anchors, and palette max C per family, plotted by hue

## validate_apps.rb
Read-only check. Validates icon structure (canvas size, group IDs, shadow presence). Exits non-zero on failure.
