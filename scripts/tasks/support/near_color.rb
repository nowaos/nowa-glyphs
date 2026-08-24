# Returns the nearest palette color for a given hex.
#
# Usage:
#   rake support:near_color -- "#4a90d9"
#   rake support:near_color -- 4a90d9          # # is optional
#   rake support:near_color -- 4a90d9 -P design/v4/palette.yaml

require_relative '../../lib/palette'

ROOT            = File.expand_path('../../..', __dir__)
DEFAULT_PALETTE = File.join(ROOT, 'design/v4/palette.yaml')

ARGV.delete('--')
palette_flag = ARGV.index('-P')
if palette_flag
  palette_path = ARGV.delete_at(palette_flag + 1)
  ARGV.delete_at(palette_flag)
else
  palette_path = DEFAULT_PALETTE
end

abort "Usage: rake support:near_color -- <hex> [-P palette.yaml]" if ARGV.empty?

palette = Palette.load(palette_path)

swatch = ->(hex) {
  r, g, b = hex.delete_prefix('#').scan(/../).map { |c| c.to_i(16) }
  "\e[48;2;#{r};#{g};#{b}m  \e[0m"
}

ARGV.each do |arg|
  hex = "##{arg.delete_prefix('#').downcase}"
  unless hex.match?(/\A#[0-9a-f]{6}\z/)
    puts "  #{hex}: invalid hex"
    next
  end

  nearest = palette.map_to_closest([hex])[hex]
  code    = palette.code_for(nearest)
  label   = code ? " (#{code})" : ''

  puts "  #{swatch.(hex)} #{hex}  →  #{swatch.(nearest)} #{nearest}#{label}"
end
