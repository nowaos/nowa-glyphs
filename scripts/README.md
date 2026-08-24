# scripts/

## lib/
Domain-agnostic classes. Can be used and tested in isolation.

- `palette.rb` — OKLCH color math; nearest-palette mapping via hue-family + chroma tiebreak
- `svg_tracker.rb` — SVG parsing and manipulation (Nokogiri wrapper)

## core/
Domain-aware orchestration. Knows where icons live and how the theme is structured. Depends on `lib/`.

- `icon_preprocessor.rb` — batch file processing with `Builder`/`Args` API

## tasks/
All runnable tasks live here, organized by namespace. Use Rake to list or run them:

```sh
rake -T                                               # list all tasks
rake fix:normalize_color sandbox                      # run a task with arguments
rake fix:normalize_color sandbox --scope bg,art -v 2  # with flags
rake test                                             # run the test suite
```

Namespaces are named after what the task acts on, not what it does:

- `apps/` — operations on a single app's identity: audit, rename, set its background
- `changes/` — promote or discard the versioned (`.vN`) files a task produced
- `fix/` — mechanical corrections applied in bulk across many files
- `links/` — inspect or create the symlinks under `links/`
- `support/` — calculations and generated artifacts for design work

`fix/` and `apps/` both write to icons; the line between them is scope. A task that
sweeps a directory correcting the same thing everywhere belongs in `fix/`; a task
you point at one app belongs in `apps/`.
