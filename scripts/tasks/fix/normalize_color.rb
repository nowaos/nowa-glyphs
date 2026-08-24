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
require_relative '../../core/icon_preprocessor'
require_relative '../../lib/palette'

ROOT            = File.expand_path('../../..', __dir__)
DEFAULT_PALETTE = File.join(ROOT, 'design/v4/palette.yaml')
DEFAULT_REFS    = File.join(ROOT, 'design/v4/refs.yaml')

args = IconPreprocessor::Args.new
palette_path = args.fetch('P') || DEFAULT_PALETTE
palette = Palette.load(palette_path)

# Forced overrides live under `remap:` in the refs file, alongside the
# backgrounds apps:set_bg reads. -m points at a different refs file.
if (refs_path = args.fetch('m'))
  refs_path = File.absolute_path?(refs_path) ? refs_path : File.join(ROOT, refs_path)
  abort "Refs file not found: #{refs_path}" unless File.exist?(refs_path)
else
  refs_path = DEFAULT_REFS
end

raw   = File.exist?(refs_path) ? (YAML.load_file(refs_path) || {}) : {}
remap = (raw['remap'] || {})
        .transform_keys { |k| "##{k.to_s.downcase.delete_prefix('#')}" }
        .transform_values { |v| "##{v.to_s.downcase.delete_prefix('#')}" }

IconPreprocessor.each(summary: true, abort_if_versioned: true) do |builder, tracker|
  scope  = builder.args.fetch('scope')
  colors = scope ? tracker.colors_in(scope.split(',')) : tracker.all_colors
  next if colors.empty?

  mapping = palette.map_to_closest(colors)
  mapping.merge!(remap.slice(*mapping.keys))

  root = File.expand_path('../../..', __dir__)
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
