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
rake -T                                        # list all tasks
rake fix:recolor sandbox                       # run a task with arguments
rake fix:recolor sandbox --scope bg,art -v 2   # with flags
rake test                                      # run the test suite
```
