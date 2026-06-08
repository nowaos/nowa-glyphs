# scripts/

## lib/
Domain-agnostic classes. They know nothing about icon paths, theme structure, or Nowa Glyphs conventions — only about the formats they handle (SVG, color math). Can be reused or tested in isolation.

- `svg_tracker.rb` — SVG parsing and manipulation (Nokogiri wrapper)
- `palette.rb` — OKLCH color math and palette loading

## core/
Domain-aware orchestration. Knows where icons live, what templates exist, and how the theme is structured. Depends on `lib/`.

- `icon_preprocessor.rb` — batch processing, file I/O, CLI arguments

## autofixes/
Non-destructive transforms. Each script produces a new versioned file (`.v2`, `.v3`, …) rather than editing the original. Run `commit_changes.rb` to promote a version to the original.

- `reapply_shadows.rb` — replaces the drop shadow group with the canonical template
- `recolor.rb` — remaps icon colors to the nearest palette entry

## validations/
Read-only checks. Exit non-zero on failure, used in CI.

- `validate_apps.rb` — validates icon structure (canvas size, group ids, shadow presence)

## palette/
Palette generators. Output to `design/assets/`.

- `v3/gen_palette.rb` — generates `palette-data.js` and `palette.yaml`
