# Remaps icon colors to the nearest palette entry.
# Creates a new versioned file (e.g. icon.v2.svg) — never edits the original.
#
# Usage:
#   rake fix:normalize_color src/apps/scalable/gnome-core                  # one category
#   rake fix:normalize_color src/apps/scalable/gnome-core/org.gnome.Clocks.svg  # one icon
#   rake fix:normalize_color src/... --scope bg,art,em                     # restrict to specific layers
#   rake fix:normalize_color src/... -v 2                                  # force version number
#   rake fix:normalize_color src/... -P color-study/nowa-v8.yaml           # custom palette
#   rake fix:normalize_color src/... -m design/v5/refs.yaml               # refs file with the remap

require 'yaml'
require_relative '../../core/cli'
require_relative '../../core/paths'
require_relative '../../core/sources'
require_relative '../../core/version'
require_relative '../../lib/svg_tracker'
require_relative '../../lib/palette'

DEFAULT_PALETTE = Paths::ROOT / 'design/v4/palette.yaml'
DEFAULT_REFS    = Paths::ROOT / 'design/v4/refs.yaml'

cli     = Cli.parse(ARGV, flags: %i[indent multiline], values: %i[scope v tag P m])
palette = Palette.load(cli.value(:P) || DEFAULT_PALETTE)

# Forced overrides live under `remap:` in the refs file, alongside the
# backgrounds apps:set_bg reads. -m points at a different refs file.
if (refs_path = cli.value(:m))
  refs_path = Paths.absolute(refs_path)
  abort "Refs file not found: #{refs_path}" unless File.exist?(refs_path)
else
  refs_path = DEFAULT_REFS
end

raw   = File.exist?(refs_path) ? (YAML.load_file(refs_path) || {}) : {}
remap = (raw['remap'] || {})
        .transform_keys { |k| "##{k.to_s.downcase.delete_prefix('#')}" }
        .transform_values { |v| "##{v.to_s.downcase.delete_prefix('#')}" }

files = Sources.resolve(cli.path, fallback: Paths::SRC).reject_symlinks!

adding = cli.value(:v) || cli.value(:tag)
adding ? files.reject_versions! : Version.assert_clean!(files.to_a)

fmt     = { indent: cli.multiline? || cli.indent?, multiline: cli.multiline? }
scope   = cli.value(:scope)
created = 0

files.each do |path|
  tracker = SvgTracker.new(path)
  colors  = scope ? tracker.colors_in(scope.split(',')) : tracker.all_colors
  next if colors.empty?

  mapping = palette.map_to_closest(colors)
  mapping.merge!(remap.slice(*mapping.keys))

  rel = Paths.relative(path)
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
  tracker.save(Version.dest(path, tag: cli.value(:tag), n: cli.value(:v)&.to_i), **fmt)
  created += 1
end

puts "Done. #{created} file(s) processed."
