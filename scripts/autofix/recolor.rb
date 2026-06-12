# Remaps icon colors to the nearest palette entry.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   ruby scripts/autofix/recolor.rb src/apps/scalable/gnome-core                  # one category
#   ruby scripts/autofix/recolor.rb src/apps/scalable/gnome-core/org.gnome.Clocks.svg  # one icon
#   ruby scripts/autofix/recolor.rb src/... --scope bg,art,em                     # restrict to specific layers
#   ruby scripts/autofix/recolor.rb src/... -v 2                                  # force version number
#   ruby scripts/autofix/recolor.rb src/... -P color-study/nowa-v8.yaml           # custom palette

require_relative '../core/icon_preprocessor'
require_relative '../lib/palette'

DEFAULT_PALETTE = File.join(__dir__, '../../design/v4/palette.yaml')

args = IconPreprocessor::Args.new
palette_path = args.fetch('P') || DEFAULT_PALETTE
palette = Palette.load(palette_path)

IconPreprocessor.each(summary: true, abort_if_versioned: true) do |builder, tracker|
  scope  = builder.args.fetch('scope')
  colors = scope ? tracker.colors_in(scope.split(',')) : tracker.all_colors
  next if colors.empty?

  mapping = palette.map_to_closest(colors)

  root = File.expand_path('../..', __dir__)
  rel  = Pathname.new(tracker.path).relative_path_from(root)
  puts "\e[32m[#{rel}]\e[0m"
  swatch = ->(hex) {
    r, g, b = hex[1..].scan(/../).map { |c| c.to_i(16) }
    "\e[48;2;#{r};#{g};#{b}m  \e[0m"
  }
  mapping.each do |from, to|
    code = palette.code_for(to)
    puts "  - #{swatch.(from)} #{from} -> #{swatch.(to)} #{to}#{code ? " (#{code})" : ''}"
  end
  puts

  tracker.replace_colors!(mapping)
  builder.create_version
end
