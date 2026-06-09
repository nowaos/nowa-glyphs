# scripts/

## lib/
Domain-agnostic classes. Know nothing about icon paths or theme structure — only about the formats they handle. Can be reused or tested in isolation.

- `palette.rb` — OKLCH color math; hue-family mapping (circular mean + chroma tiebreak) to find the nearest palette entry
- `svg_tracker.rb` — SVG parsing and manipulation (Nokogiri wrapper); color extraction, replacement, group operations, save with optional indent/multiline formatting

## core/
Domain-aware orchestration. Knows where icons live, what templates exist, and how the theme is structured. Depends on `lib/`.

- `icon_preprocessor.rb` — batch file processing with `Builder`/`Args` API (see below)

## autofix/
Non-destructive transforms. Each script creates a new versioned file (`.v2`, `.v3`, …) — the original is never edited. Run `apply_changes.rb` to promote a version to the original.

- `recolor.rb` — remaps icon colors to the nearest palette entry. Use `--non-apps` to recolor all colors instead of only those in `bg`/`art`/`em` groups
- `update_shadows.rb` — replaces the drop shadow group (`#ds`) with the canonical template
- `clean_svg.rb` — validates (and optionally removes) metadata nodes, unused defs, and shapes outside the viewBox
- `apply_changes.rb` — promotes `.vN` files back to their originals. Single vN → auto; multiple → prompts. Supports `--dry-run`
- `undo_changes.rb` — deletes all `.vN` files in the target area, leaving only originals. Supports `--dry-run`

### Targeting
Pass a path (relative to project root) as the first argument — file or directory. **Required**: omitting it aborts with an error.

```sh
ruby scripts/autofix/recolor.rb                              # all icons
ruby scripts/autofix/recolor.rb src/apps/scalable/gnome-core # one category
ruby scripts/autofix/recolor.rb test/fixtures/square.svg     # one file
```

### Common flags

| Flag | Description |
|---|---|
| `--tag <name>` | Named output (`icon-name.svg`) — skips version bump and the versioned-file guard |
| `--non-apps` | Recolor all colors in the document, not just `bg`/`art`/`em` groups (`recolor.rb` only) |
| `--indent` | Save versioned output with 2-space indentation |
| `--multiline` | Save versioned output with attributes on separate lines (implies `--indent`) |
| `--fix` | Apply fixes and create a versioned file (`clean_svg.rb` only) |
| `--dry-run` | Preview actions without writing files (`apply_changes`, `undo_changes`) |

## IconPreprocessor API

Scripts that process icons use `IconPreprocessor.each`:

```ruby
IconPreprocessor.each(summary: true, abort_if_versioned: true) do |builder, tracker|
  # tracker — SvgTracker instance for the current file
  # builder — controls output and provides helpers
end
```

**`builder` methods:**

| Method | Description |
|---|---|
| `builder.create_version` | Saves a versioned copy (`.vN`). Respects `--indent`/`--multiline`/`--tag` flags |
| `builder.template_from(filename)` | Returns full path to `src/apps/templates/<filename>`, aborts if missing |
| `builder.has_pending_version?` | True if a `.vN` sibling already exists for this file |
| `builder.versioned?` | True if `create_version` was called for this file |
| `builder.args` | `Args` instance for reading CLI flags |

**`builder.args` methods:**

| Method | Example | Description |
|---|---|---|
| `args.fetch('name')` | `args.fetch('tag')` | Returns the value after `--name`/`-name`, or `nil` |
| `args.includes?('flag')` | `args.includes?('non-apps')` | True if `--flag`/`-flag` is present |

**`each` options:**

| Option | Default | Description |
|---|---|---|
| `summary:` | `false` | Prints `Done. N file(s) processed.` at the end |
| `abort_if_versioned:` | `false` | Aborts if any selected file already has a `.vN` sibling (skipped when `--tag` is set) |

## validate_apps.rb
Read-only check. Validates icon structure (canvas size, group IDs, shadow presence). Exits non-zero on failure.
