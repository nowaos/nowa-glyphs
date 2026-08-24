#!/usr/bin/env ruby
# Repaints the #bg gradient with the light or dark background from design/v4/refs.yaml.
#
# The gradient runs corner to corner: top-right (first color, lighter) to
# bottom-left (second color, darker). Any gradient the #bg used before is
# dropped from defs. Overwrites the original file.
#
# Usage:
#   rake apps:set_bg -- src/apps/scalable/_internet --dark
#   rake apps:set_bg -- src/apps/scalable/_internet/uget.svg --light
#   rake apps:set_bg -- src/apps/scalable --dark --multiline

require 'yaml'
require 'nokogiri'
require_relative '../../core/icon_preprocessor'

ROOT  = File.expand_path('../../..', __dir__)
REFS  = File.join(ROOT, 'design/v4/refs.yaml')
BG_ID = 'bg'

args  = IconPreprocessor::Args.new
theme = %w[light dark].find { |t| args.includes?(t) }
abort 'Usage: rake apps:set_bg -- <path> --light|--dark' unless theme

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

indent    = args.includes?('indent') || args.includes?('multiline')
multiline = args.includes?('multiline')
changed   = 0
skipped   = 0

IconPreprocessor.each do |_builder, tracker|
  rel = tracker.path.sub("#{ROOT}/", '')
  id  = repaint_bg!(tracker.doc)

  if id.nil?
    warn "skipped  #{rel} (no ##{BG_ID})"
    skipped += 1
    next
  end

  tracker.clean_defs!
  tracker.save(indent: indent, multiline: multiline)
  puts "#{theme.ljust(5)}  #{rel}  ##{id}"
  changed += 1
end

puts "Done. #{changed} file(s) updated#{skipped.zero? ? '' : ", #{skipped} skipped"}."
