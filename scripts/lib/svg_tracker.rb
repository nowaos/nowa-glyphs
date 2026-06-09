#!/usr/bin/env ruby
require 'nokogiri'

class SvgTracker
  IGNORED_TAGS = %w[defs metadata namedview]

  attr_reader :path

  def initialize(path)
    @path = path
    @doc = Nokogiri::XML(File.read(path))
  end

  def has_size?(w, h)
    svg = @doc.at_css('svg')
    svg && svg['width'] == w.to_s && svg['height'] == h.to_s
  end

  def scaled?
    svg = @doc.at_css('svg')
    
    return false if !svg
    
    vb = svg['viewBox']
    w  = svg['width']
    h  = svg['height']

    vb && vb != "0 0 #{w} #{h}"
  end

  def has?(tag, attrs = {})
    nodes = find_nodes(tag)
    nodes.any? { |node| match_attrs?(node, attrs) }
  end

  def match_at(path, tag, attrs = {}, &block)
    node = get_node_by_path(@doc.at_css('svg'), path)

    return nil unless node
    return nil if tag != :any && node.name != tag.to_s
    return nil unless match_attrs?(node, attrs)
    return nil if block && !block.call(node)

    node
  end

  def matches_in(path, tag, attrs = {}, &block)
    parent = get_node_by_path(@doc.at_css('svg'), path)
    return [] unless parent

    children = parent.element_children.reject { |c| IGNORED_TAGS.include?(c.name) }

    children.select do |child|
      next false if tag != :any && child.name != tag.to_s
      next false unless match_attrs?(child, attrs)
      block ? block.call(child) : true
    end
  end

  def match_in(path, tag, attrs = {}, &block)
    matches_in(path, tag, attrs, &block).first
  end

  def update_attributes(node, new_attrs)
    new_attrs.each do |k, v|
      key = k.to_s.tr('_', '-')

      if v.nil?
        node.remove_attribute(key)
      else
        node[key] = v
      end
    end
  end

  def group(path, range, id: nil, wrap: true)
    parent = get_node_by_path(@doc.at_css('svg'), path)
    raise "Path inválido" unless parent

    # filhos 'visíveis' (ignora defs/metadata, como no get_node_by_path)
    vis_children = parent.element_children.reject { |c| IGNORED_TAGS.include?(c.name) }

    # seleciona pelo range
    selected = vis_children[range]
    selected = [selected] if selected && !selected.is_a?(Array)
    selected ||= []
    return nil if selected.empty?

    # se wrap == false e o único selecionado já é um <g>, apenas (re)defina o id (se passado) e retorne
    if !wrap && selected.size == 1 && selected.first.name == "g"
      selected.first['id'] = id if id
      return selected.first
    end

    # cria novo grupo
    g = Nokogiri::XML::Node.new('g', @doc)
    g['id'] = id if id

    # insere o grupo antes do primeiro selecionado
    anchor = selected.first
    anchor.add_previous_sibling(g)

    # move os selecionados para dentro do grupo (na ordem)
    selected.each { |child| g.add_child(child.unlink) }

    g
  end

  def merge!(other_path, position: :after)
    other_doc  = Nokogiri::XML(File.read(other_path))
    other_root = other_doc.at_css("svg")
    current_root = @doc.at_css("svg")

    raise "Invalid SVG" unless other_root && current_root

    other_visible = other_root.element_children.reject { |c| IGNORED_TAGS.include?(c.name) }
    current_visible = current_root.element_children.reject { |c| IGNORED_TAGS.include?(c.name) }

    if position == :before
      anchor = current_visible.first

      other_visible.each do |node|
        anchor.add_previous_sibling(node.dup) if anchor
        current_root.add_child(node.dup) unless anchor
        anchor = node
      end
    else
      anchor = current_visible.last

      other_visible.each do |node|
        anchor.add_next_sibling(node.dup) if anchor
        current_root.add_child(node.dup) unless anchor
        anchor = node
      end
    end

    other_defs = other_root.css("defs > *")
    unless other_defs.empty?
      current_defs = current_root.at_css("defs")
      unless current_defs
        current_defs = Nokogiri::XML::Node.new("defs", @doc)
        current_root.children.first ?
          current_root.children.first.add_previous_sibling(current_defs) :
          current_root.add_child(current_defs)
      end
      other_defs.each { |d| current_defs.add_child(d.dup) }
    end

    self
  end

  def merged_equal?(node, other_path, other_id)
    other_tracker = SvgTracker.new(other_path)
    other_node = other_tracker.match_in([], :any, id: other_id)
    return false unless other_node

    normalize(node) == normalize(other_node)
  end

  def clean_defs!
    defs = @doc.at_css('defs')
    return self unless defs

    loop do
      referenced = collect_referenced_ids
      removed = 0
      defs.element_children.each do |child|
        unless referenced.include?(child['id'])
          child.remove
          removed += 1
        end
      end
      break if removed == 0
    end

    self
  end

  def unused_def_nodes
    defs = @doc.at_css('defs')
    return [] unless defs
    referenced = collect_referenced_ids
    defs.element_children.reject { |child| referenced.include?(child['id']) }
  end

  def metadata_nodes
    @doc.css('title, desc, metadata').to_a
  end

  def clean_metadata!
    metadata_nodes.each(&:remove)
    self
  end

  EDITOR_NS = %w[
    http://www.inkscape.org/namespaces/inkscape
    http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd
  ].to_set.freeze

  def inkscape_nodes
    result = []
    @doc.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      result << node if EDITOR_NS.include?(node.namespace&.href)
    end
    result
  end

  def inkscape_attr_count
    count = 0
    @doc.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      count += node.attribute_nodes.count { |a| EDITOR_NS.include?(a.namespace&.href) }
    end
    count
  end

  def clean_inkscape!
    to_remove = []
    @doc.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      if EDITOR_NS.include?(node.namespace&.href)
        to_remove << node
      else
        node.attribute_nodes
            .select { |a| EDITOR_NS.include?(a.namespace&.href) }
            .each(&:remove)
      end
    end
    to_remove.each(&:remove)
    self
  end

  def outside_viewbox_nodes
    svg   = @doc.at_css('svg')
    return [] unless svg
    vb = svg['viewBox']&.split(/[\s,]+/)&.map(&:to_f)
    return [] unless vb&.size == 4
    vx, vy, vw, vh = vb
    vx2, vy2 = vx + vw, vy + vh

    ignored_ancestors = %w[defs clipPath mask pattern]
    result = []

    @doc.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      next if node.ancestors.any? { |a| ignored_ancestors.include?(a.name) }
      bounds = element_bounds(node)
      next unless bounds
      bx1, by1, bx2, by2 = bounds
      result << node if bx2 < vx || bx1 > vx2 || by2 < vy || by1 > vy2
    end

    result
  end

  # Returns a Set of all hex colors used anywhere in the document.
  def all_colors
    colors = Set.new
    collect_hex_colors(@doc.at_css('svg'), colors)
    colors
  end

  # Returns a Set of all hex colors used in the given groups and their referenced defs.
  def colors_in(group_ids)
    refs = Set.new
    group_ids.each do |gid|
      node = @doc.at_css("##{gid}")
      collect_color_refs(node, refs) if node
    end
    expand_color_refs(refs)

    colors = Set.new
    refs.each do |id|
      el = @doc.at_css('defs')&.children&.find { |n| n['id'] == id }
      collect_hex_colors(el, colors) if el
    end
    group_ids.each do |gid|
      node = @doc.at_css("##{gid}")
      collect_hex_colors(node, colors) if node
    end
    colors
  end

  # Applies a { hex => hex } mapping across the document.
  # Safe to run globally — the mapping only contains in-scope colors.
  def replace_colors!(mapping)
    @doc.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      COLOR_ATTRS.each { |a| remap_attribute!(node, a, mapping) }
      remap_inline_style!(node, mapping)
    end
  end

  def save(path = nil, indent: false, multiline: false)
    xml = (indent || multiline) ? @doc.to_xml(indent: 2) : @doc.to_xml
    xml = strip_editor_xmlns(xml)
    xml = strip_blank_lines(xml)
    xml = format_multiline_attrs(xml) if multiline
    File.write(path || @path, xml)
  end

  private

  COLOR_ATTRS = %w[fill stroke stop-color].freeze

  def collect_color_refs(node, refs)
    COLOR_ATTRS.each { |a| refs.merge(url_refs_in(node[a])) }
    if (style = node['style'])
      style.split(';').each do |part|
        k, v = part.split(':', 2).map(&:strip)
        refs.merge(url_refs_in(v)) if COLOR_ATTRS.include?(k.to_s.downcase)
      end
    end
    node.element_children.each { |c| collect_color_refs(c, refs) }
  end

  def expand_color_refs(refs)
    defs = @doc.at_css('defs')
    return unless defs

    queue = refs.to_a.dup
    while (id = queue.shift)
      el = defs.children.find { |n| n['id'] == id }
      next unless el

      href = el['xlink:href'] || el['href']
      if href&.start_with?('#')
        ref = href[1..]
        unless refs.include?(ref)
          refs.add(ref)
          queue << ref
        end
      end

      nested = Set.new
      collect_color_refs(el, nested)
      nested.each do |r|
        unless refs.include?(r)
          refs.add(r)
          queue << r
        end
      end
    end
  end

  def collect_hex_colors(node, colors)
    node.traverse do |n|
      next unless n.is_a?(Nokogiri::XML::Element)
      COLOR_ATTRS.each { |a| colors.merge(hex_values_in(n[a])) }
      colors.merge(hex_values_in(n['style']))
    end
  end

  def hex_values_in(val)
    return [] unless val
    val.scan(/#[0-9a-fA-F]{6}\b/).map(&:downcase)
  end

  def url_refs_in(val)
    return [] unless val
    val.scan(/url\(#([^)]+)\)/).flatten
  end

  def collect_referenced_ids
    referenced = Set.new
    scan_refs = ->(node) {
      node.attributes.each_value do |attr|
        attr.value.scan(/url\(#([^)]+)\)/) { referenced << $1 }
        attr.value.scan(/^#(.+)/)          { referenced << $1 }
      end
    }
    @doc.traverse do |node|
      next if node.ancestors.any? { |a| a.name == 'defs' }
      next unless node.is_a?(Nokogiri::XML::Element)
      scan_refs.call(node)
    end
    @doc.at_css('defs')&.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      scan_refs.call(node)
    end
    referenced
  end

  EDITOR_XMLNS_PREFIXES = %w[inkscape sodipodi rdf cc dc svg xlink].freeze

  def strip_editor_xmlns(xml)
    EDITOR_XMLNS_PREFIXES.reduce(xml) do |s, prefix|
      candidate = s.gsub(/[ \t]+xmlns:#{prefix}="[^"]*"/, '')
      candidate.match?(/\b#{Regexp.escape(prefix)}:/) ? s : candidate
    end
  end

  def strip_blank_lines(xml)
    xml.gsub(/\n[ \t]*\n/, "\n")
  end

  def format_multiline_attrs(xml, threshold: 3)
    result = []
    xml.each_line do |line|
      m = line.chomp.match(/^(\s*)<([a-zA-Z][^\s\/>]*)(\s.+?)(\s*\/?>)\s*$/)
      unless m
        result << line
        next
      end
      indent, tag, attrs_str, close = m[1], m[2], m[3], m[4].strip
      attrs = attrs_str.scan(/([^\s=]+)="([^"]*)"/).map { |k, v| %(#{k}="#{v}") }
      if attrs.size < threshold
        result << line
        next
      end
      result << "#{indent}<#{tag}\n"
      attrs.each { |a| result << "#{indent}  #{a}\n" }
      result << "#{indent}#{close}\n"
    end
    result.join
  end

  SHAPE_TAGS = %w[rect circle ellipse line path polygon polyline image].freeze

  def element_bounds(node)
    return nil unless SHAPE_TAGS.include?(node.name)
    case node.name
    when 'rect'
      x, y, w, h = node['x'].to_f, node['y'].to_f, node['width'].to_f, node['height'].to_f
      return nil if w.zero? && h.zero?
      [x, y, x + w, y + h]
    when 'circle'
      cx, cy, r = node['cx'].to_f, node['cy'].to_f, node['r'].to_f
      return nil if r.zero?
      [cx - r, cy - r, cx + r, cy + r]
    when 'ellipse'
      cx, cy, rx, ry = node['cx'].to_f, node['cy'].to_f, node['rx'].to_f, node['ry'].to_f
      return nil if rx.zero? && ry.zero?
      [cx - rx, cy - ry, cx + rx, cy + ry]
    when 'line'
      x1, y1, x2, y2 = node['x1'].to_f, node['y1'].to_f, node['x2'].to_f, node['y2'].to_f
      [[x1, x2].min, [y1, y2].min, [x1, x2].max, [y1, y2].max]
    when 'path'
      path_bounds(node['d'])
    when 'polygon', 'polyline'
      pts = node['points']&.scan(/-?[\d.]+/)&.map(&:to_f)
      return nil unless pts && pts.size >= 2
      xs = pts.each_slice(2).map(&:first)
      ys = pts.each_slice(2).map(&:last)
      [xs.min, ys.min, xs.max, ys.max]
    when 'image'
      x, y, w, h = node['x'].to_f, node['y'].to_f, node['width'].to_f, node['height'].to_f
      [x, y, x + w, y + h]
    end
  end

  def path_bounds(d)
    return nil unless d
    xs, ys = [], []
    d.scan(/[ML]\s*(-?[\d.]+)[\s,]+(-?[\d.]+)/) { xs << $1.to_f; ys << $2.to_f }
    d.scan(/H(-?[\d.]+)/)                        { xs << $1.to_f }
    d.scan(/V(-?[\d.]+)/)                        { ys << $1.to_f }
    return nil if xs.empty? && ys.empty?
    xs = [0.0] if xs.empty?
    ys = [0.0] if ys.empty?
    [xs.min, ys.min, xs.max, ys.max]
  end

  def remap_attribute!(node, attr, mapping)
    val = node[attr]
    return unless val
    new_val = val.gsub(/#[0-9a-fA-F]{6}\b/) { |hex| mapping.fetch(hex.downcase, hex) }
    node[attr] = new_val if new_val != val
  end

  def remap_inline_style!(node, mapping)
    return unless (style = node['style'])
    new_style = style.gsub(/#[0-9a-fA-F]{6}\b/) { |hex| mapping.fetch(hex.downcase, hex) }
    node['style'] = new_style if new_style != style
  end

  def normalize (node)
    node.to_xml.gsub(/ xmlns="[^"]*"/, '').gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
  end

  def get_node_by_path(node, path)
    current = node

    path.each do |idx|
      children = current.element_children.reject { |c| IGNORED_TAGS.include?(c.name) }
      
      return nil unless idx < children.size
      
      current = children[idx]
    end

    current
  end

  def find_nodes(tag)
    nodes = @doc.xpath('//*[not(ancestor::metadata) and not(ancestor::defs)]')
    nodes = nodes.select { |n| n.name == tag.to_s } unless tag == :any
    nodes
  end

  def match_attrs?(node, attrs)
    attrs.all? do |key, value|
      key = key.to_s.tr('_', '-')

      if value.is_a?(Hash)
        svg_hash = node[key.to_s] ? style_to_hash(node[key.to_s]) : {}
        value.all? do |sub_key, sub_value|
          sub_key = sub_key.to_s.tr('_', '-')
          if sub_value == true
            svg_hash.key?(sub_key)
          elsif sub_value == false
            !svg_hash.key?(sub_key)
          elsif numeric?(sub_value) && numeric?(svg_hash[sub_key])
            round(svg_hash[sub_key].to_f) == round(sub_value.to_f)
          else
            svg_hash[sub_key] == sub_value.to_s
          end
        end
      elsif value == true
        node.has_attribute?(key.to_s)
      elsif value == false
        !node.has_attribute?(key.to_s)
      elsif numeric?(value) && numeric?(node[key.to_s])
        round(node[key.to_s].to_f) == round(value.to_f)
      else
        node[key.to_s] == value.to_s
      end
    end
  end

  def style_to_hash(style_str)
    style_str.split(';').map { |pair| pair.split(':', 2) }.to_h
  end

  def numeric?(v)
    Float(v) != nil rescue false
  end

  def round(v)
    (v * 100).round / 100.0
  end
end
