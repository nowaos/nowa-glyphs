# Remaps icon colors to the nearest palette entry.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   ruby scripts/autofixes/recolor.rb                                      # all icons in src/apps/scalable/
#   ruby scripts/autofixes/recolor.rb -d src/apps/scalable/gnome-core      # one category
#   ruby scripts/autofixes/recolor.rb -d design/test                       # design test icons
#   ruby scripts/autofixes/recolor.rb -f org.gnome.Clocks.svg              # one icon by filename
#   ruby scripts/autofixes/recolor.rb -f design/test/flash.svg             # explicit path from project root

require_relative '../core/icon_preprocessor'
require_relative '../lib/palette'

palette = Palette.load(File.join(__dir__, '../../design/assets/palette.yaml'))

IconPreprocessor.update do |tracker, _|
  colors = tracker.colors_in(%w[bg art em])
  mapping = palette.map_to_closest(colors)

  tracker.replace_colors!(mapping)
end
