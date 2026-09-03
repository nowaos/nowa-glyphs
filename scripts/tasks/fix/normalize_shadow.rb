# Replaces the drop shadow group (#ds) with the canonical template.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   rake fix:normalize_shadow                                                        # all icons in src/apps/scalable/
#   rake fix:normalize_shadow src/apps/scalable/gnome-core                           # one category
#   rake fix:normalize_shadow src/apps/scalable/gnome-core/org.gnome.Clocks.svg      # one icon

require_relative '../../core/cli'
require_relative '../../core/paths'
require_relative '../../core/sources'
require_relative '../../core/template'
require_relative '../../core/version'
require_relative '../../lib/svg_tracker'

cli   = Cli.parse(ARGV, flags: %i[indent multiline], values: %i[v tag])
files = Sources.resolve(cli.path, fallback: Paths::SRC).reject_symlinks!

adding = cli.value(:v) || cli.value(:tag)
adding ? files.reject_versions! : Version.assert_clean!(files.to_a)

fmt     = { indent: cli.multiline? || cli.indent?, multiline: cli.multiline? }
created = 0

files.each do |path|
  tracker = SvgTracker.new(path)
  tracker.match_in([], :any, id: 'ds')&.remove
  tracker.clean_defs!

  bg  = tracker.match_in([], :any, id: 'bg')
  tpl = Template.apps(bg['rx'] == '27.5' ? 'ds-round.svg' : 'ds.svg')

  tracker.merge!(tpl, position: :before)
  tracker.save(Version.dest(path, tag: cli.value(:tag), n: cli.value(:v)&.to_i), **fmt)
  created += 1
end

puts "Done. #{created} file(s) processed."
