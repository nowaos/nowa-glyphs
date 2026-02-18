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
      # collect all referenced IDs outside defs
      referenced = Set.new

      @doc.traverse do |node|
        next if node.ancestors.any? { |a| a.name == 'defs' }
        next unless node.is_a?(Nokogiri::XML::Element)

        node.attributes.each_value do |attr|
          attr.value.scan(/url\(#([^)]+)\)/) { referenced << $1 }
          attr.value.scan(/^#(.+)/)          { referenced << $1 }
        end
      end

      # also collect IDs referenced from within defs (xlink:href, href between defs)
      defs.traverse do |node|
        next unless node.is_a?(Nokogiri::XML::Element)

        node.attributes.each_value do |attr|
          attr.value.scan(/url\(#([^)]+)\)/) { referenced << $1 }
          attr.value.scan(/^#(.+)/)          { referenced << $1 }
        end
      end

      # remove unreferenced defs children
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

  def save(path = nil)
    File.write(path || @path, @doc.to_xml)
  end

  private

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
