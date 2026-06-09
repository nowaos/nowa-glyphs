# Remaps icon colors to the nearest palette entry.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   ruby scripts/autofix/recolor.rb                                               # all icons in src/apps/scalable/
#   ruby scripts/autofix/recolor.rb src/apps/scalable/gnome-core                  # one category
#   ruby scripts/autofix/recolor.rb src/apps/scalable/gnome-core/org.gnome.Clocks.svg  # one icon
#   ruby scripts/autofix/recolor.rb src/apps/scalable/gnome-core/org.gnome.Clocks.svg --tag experiment
#   ruby scripts/autofix/recolor.rb sandbox --non-apps                            # recolor all colors (no bg/art/em structure)

require_relative '../core/icon_preprocessor'
require_relative '../lib/palette'

palette = Palette.load(File.join(__dir__, '../../design/assets/palette.yaml'))

IconPreprocessor.each(summary: true, abort_if_versioned: true) do |builder, tracker|
  colors = builder.args.includes?('non-apps') ? tracker.all_colors : tracker.colors_in(%w[bg art em])
  next if colors.empty?

  tracker.replace_colors!(palette.map_to_closest(colors))
  builder.create_version
end
