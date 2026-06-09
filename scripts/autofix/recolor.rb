# Remaps icon colors to the nearest palette entry.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   ruby scripts/autofix/recolor.rb                                            # all icons in src/apps/scalable/
#   ruby scripts/autofix/recolor.rb -d src/apps/scalable/gnome-core            # one category
#   ruby scripts/autofix/recolor.rb -d test                                    # test icons
#   ruby scripts/autofix/recolor.rb -f org.gnome.Clocks.svg                    # one icon by filename
#   ruby scripts/autofix/recolor.rb -f design/test/flash.svg                   # explicit path from project root
#   ruby scripts/autofix/recolor.rb -f org.gnome.Clocks.svg --tag experiment   # named output, no version bump
#   ruby scripts/autofix/recolor.rb -d test --non-apps                         # recolor all colors (no bg/art/em structure)

require_relative '../core/icon_preprocessor'
require_relative '../lib/palette'

palette = Palette.load(File.join(__dir__, '../../design/assets/palette.yaml'))

IconPreprocessor.update do |tracker, _|
  colors = if IconPreprocessor.args.non_apps
    tracker.all_colors
  else
    tracker.colors_in(%w[bg art em])
  end

  next false if colors.empty?

  mapping = palette.map_to_closest(colors)
  tracker.replace_colors!(mapping)
end
