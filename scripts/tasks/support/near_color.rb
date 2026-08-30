# Returns the nearest palette color for a given hex.
#
# With no hex argument, the hex is read from the clipboard (wl-paste); the match
# is printed as usual and the nearest color is written back to the clipboard
# (wl-copy).
#
# Usage:
#   rake support:near_color -- "#4a90d9"
#   rake support:near_color -- 4a90d9          # # is optional
#   rake support:near_color                    # hex comes from the clipboard
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

# Current clipboard text, trimmed; aborts if wl-paste is missing or the
# clipboard is empty.
def clipboard_read
  text = IO.popen(['wl-paste', '--no-newline'], &:read)
  abort 'Error: clipboard is empty or unreadable' unless $?.success? && text && !text.strip.empty?
  text.strip
rescue Errno::ENOENT
  abort 'Error: wl-paste not found — install wl-clipboard'
end

# Replaces the clipboard contents with text (no trailing newline).
def clipboard_write(text)
  IO.popen(['wl-copy'], 'w') { |io| io.write(text) }
rescue Errno::ENOENT
  abort 'Error: wl-copy not found — install wl-clipboard'
end

from_clipboard = ARGV.empty?
inputs         = from_clipboard ? [clipboard_read] : ARGV.dup

palette = Palette.load(palette_path)

swatch = ->(hex) {
  r, g, b = hex.delete_prefix('#').scan(/../).map { |c| c.to_i(16) }
  "\e[48;2;#{r};#{g};#{b}m  \e[0m"
}

inputs.each do |arg|
  hex = "##{arg.strip.delete_prefix('#').downcase}"
  unless hex.match?(/\A#[0-9a-f]{6}\z/)
    puts "  #{hex}: invalid hex"
    next
  end

  nearest = palette.map_to_closest([hex])[hex]
  code    = palette.code_for(nearest)
  label   = code ? " (#{code})" : ''

  puts "  #{swatch.(hex)} #{hex}  →  #{swatch.(nearest)} #{nearest}#{label}"

  clipboard_write(nearest) if from_clipboard
end
