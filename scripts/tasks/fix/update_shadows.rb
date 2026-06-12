# Replaces the drop shadow group (#ds) with the canonical template.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   rake fix:update_shadows                                                          # all icons in src/apps/scalable/
#   rake fix:update_shadows src/apps/scalable/gnome-core                             # one category
#   rake fix:update_shadows src/apps/scalable/gnome-core/org.gnome.Clocks.svg        # one icon

require_relative '../../core/icon_preprocessor'

IconPreprocessor.each(summary: true, abort_if_versioned: true) do |builder, tracker|
  ds = tracker.match_in([], :any, id: 'ds')
  ds&.remove

  tracker.clean_defs!

  bg            = tracker.match_in([], :any, id: 'bg')
  template_path = bg['rx'] == '27.5' ? builder.template_from('ds-round.svg') : builder.template_from('ds.svg')

  tracker.merge!(template_path, position: :before)
  builder.create_version
end
