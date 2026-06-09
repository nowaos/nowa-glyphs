# Replaces the drop shadow group (#ds) with the canonical template.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   ruby scripts/autofixes/reapply_shadows.rb                                 # all icons in src/apps/scalable/
#   ruby scripts/autofixes/reapply_shadows.rb -d src/apps/scalable/gnome-core # one category
#   ruby scripts/autofixes/reapply_shadows.rb -f org.gnome.Clocks.svg         # one icon by filename

require_relative '../core/icon_preprocessor'

IconPreprocessor.update do |tracker, ds_files|
  ds = tracker.match_in([], :any, id: 'ds')
  ds&.remove

  tracker.clean_defs!

  bg = tracker.match_in([], :any, id: 'bg')
  template_path = bg['rx'] == '27.5' ? ds_files.ds_round : ds_files.ds_square

  tracker.merge!(template_path, position: :before)
end