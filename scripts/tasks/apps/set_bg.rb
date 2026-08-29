#!/usr/bin/env ruby
# Repaints the #bg gradient with the light or dark background from design/v4/refs.yaml.
#
# The gradient runs corner to corner: top-right (first color, lighter) to
# bottom-left (second color, darker). Any gradient the #bg used before is
# dropped from defs. Overwrites the original file.
#
# Takes a single SVG file (not a directory).
#
# Usage:
#   rake apps:set_bg -- src/apps/scalable/_internet/uget.svg --light
#   rake apps:set_bg -- src/apps/scalable/_internet/uget.svg --dark --multiline

require 'yaml'
require 'nokogiri'
require_relative '../../core/cli'
require_relative '../../core/paths'
require_relative '../../lib/svg_tracker'

REFS  = Paths::ROOT / 'design/v4/refs.yaml'
BG_ID = 'bg'

cli   = Cli.parse(ARGV, flags: %i[light dark indent multiline])
theme = %w[light dark].find { |t| cli.flag?(t) }
abort 'Usage: rake apps:set_bg -- <file.svg> --light|--dark' unless theme && cli.path

target = Paths.absolute(cli.path)
abort "Error: '#{cli.path}' is not a file" unless File.file?(target)
abort "Error: '#{cli.path}' is a symlink" if File.symlink?(target)

backgrounds = YAML.load_file(REFS)['backgrounds'] || {}
stops       = backgrounds[theme]
abort "No '#{theme}' entry under 'backgrounds' in design/v4/refs.yaml" unless stops
abort "Expected 2 colors for '#{theme}', got #{Array(stops).size}" unless stops.is_a?(Array) && stops.size == 2

FROM, TO = stops

def unique_gradient_id(doc)
  loop do
    id = "linearGradient#{rand(1000..9999)}"
    return id unless doc.at_css("##{id}")
  end
end

# Whitespace the file already uses between defs children, so the appended
# gradient starts on its own line instead of gluing to the previous tag.
def indent_in(defs)
  lead = defs.children.find { |node| node.text? && node.text.match?(/\n[ \t]*\z/) }
  lead ? lead.text[/\n[ \t]*\z/] : "\n    "
end

def defs_node(doc)
  return doc.at_css('defs') if doc.at_css('defs')

  defs = Nokogiri::XML::Node.new('defs', doc)
  root = doc.at_css('svg')
  root.children.first ? root.children.first.add_previous_sibling(defs) : root.add_child(defs)
  defs
end

# fill in style wins over the fill attribute, so we always write the style and
# drop the attribute — otherwise the old color could survive in the markup.
def style_with_fill(style, value)
  pairs = (style || '').split(';').map(&:strip).reject(&:empty?)
                       .map { |pair| pair.split(':', 2).map(&:strip) }
  pairs.reject! { |key, _| key.casecmp?('fill') }
  ([['fill', value]] + pairs).map { |key, val| "#{key}:#{val}" }.join(';')
end

# objectBoundingBox places the stops on the corners of the #bg itself, so this
# holds regardless of the icon's size, position or corner radius.
def repaint_bg!(doc)
  bg = doc.at_css("##{BG_ID}")
  return nil unless bg

  id   = unique_gradient_id(doc)
  grad = Nokogiri::XML::Node.new('linearGradient', doc)
  grad['id'] = id
  grad['gradientUnits'] = 'objectBoundingBox'
  grad['x1'], grad['y1'], grad['x2'], grad['y2'] = '1', '0', '0', '1'

  { '0' => FROM, '1' => TO }.each do |offset, color|
    stop = Nokogiri::XML::Node.new('stop', doc)
    stop['offset']     = offset
    stop['stop-color'] = color
    grad.add_child(stop)
  end

  defs = defs_node(doc)
  defs.add_child(Nokogiri::XML::Text.new(indent_in(defs), doc))
  defs.add_child(grad)

  bg.remove_attribute('fill')
  bg['style'] = style_with_fill(bg['style'], "url(##{id})")

  id
end

indent    = cli.multiline? || cli.indent?
multiline = cli.multiline?
rel       = Paths.relative(target)

tracker = SvgTracker.new(target)
id      = repaint_bg!(tracker.doc)
abort "Error: #{rel} has no ##{BG_ID}" if id.nil?

tracker.clean_defs!
tracker.save(indent: indent, multiline: multiline)
puts "#{theme.ljust(5)}  #{rel}  ##{id}"
