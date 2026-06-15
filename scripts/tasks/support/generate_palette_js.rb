#!/usr/bin/env ruby
# Generates palette-data.js from a palette.yaml.
# Writes the JS file alongside the YAML (same directory).
#
# Usage:
#   rake support:generate_palette_js design/v7/palette.yaml
#   rake support:generate_palette_js design/v7
#   rake support:generate_palette_js design/v7 design/v8 design/v8_2

require 'yaml'

# Paths whose values are serialized as a single line.
# Use '*' as a wildcard for any single key or index segment.
INLINE_PATHS = %w[
  points.*.scale.*
].freeze

def inline_path?(path)
  parts = path.split('.')
  INLINE_PATHS.any? { |pat|
    pat_parts = pat.split('.')
    pat_parts.length == parts.length &&
      pat_parts.zip(parts).all? { |p, q| p == '*' || p == q }
  }
end

def to_js_inline(value)
  case value
  when Hash
    return '{}' if value.empty?
    "{ #{value.map { |k, v| "#{k}: #{to_js_inline(v)}" }.join(', ')} }"
  when Array
    return '[]' if value.empty?
    "[#{value.map { |v| to_js_inline(v) }.join(', ')}]"
  when String  then "\"#{value.gsub('"', '\\"')}\""
  when Integer then value.to_s
  when Float   then value.to_s
  when true    then 'true'
  when false   then 'false'
  when nil     then 'null'
  end
end

def to_js(value, indent = 0, path = '')
  pad  = '  ' * indent
  pad1 = '  ' * (indent + 1)
  case value
  when Hash
    return '{}' if value.empty?
    pairs = value.map { |k, v|
      child = path.empty? ? k.to_s : "#{path}.#{k}"
      inline_path?(child) ? "#{pad1}#{k}: #{to_js_inline(v)}" : "#{pad1}#{k}: #{to_js(v, indent + 1, child)}"
    }
    "{\n#{pairs.join(",\n")}\n#{pad}}"
  when Array
    return '[]' if value.empty?
    items = value.each_with_index.map { |v, i|
      child = "#{path}.#{i}"
      inline_path?(child) ? to_js_inline(v) : to_js(v, indent, child)
    }
    if items.all? { |i| !i.include?("\n") } && items.sum(&:length) < 80
      "[#{items.join(', ')}]"
    else
      "[\n#{items.map { |i| "#{pad1}#{i}" }.join(",\n")}\n#{pad}]"
    end
  when String  then "\"#{value.gsub('"', '\\"')}\""
  when Integer then value.to_s
  when Float   then value.to_s
  when true    then 'true'
  when false   then 'false'
  when nil     then 'null'
  end
end

def generate(yaml_path)
  data = YAML.load_file(yaml_path)
  dir  = File.dirname(yaml_path)
  out  = File.join(dir, 'palette-data.js')

  js = <<~JS
    ;(function() {
      window.PALETTES = window.PALETTES || {};
      window.PALETTES.current = #{to_js(data, 1)};
    })();
  JS

  File.write(out, js)
  puts "#{out} (#{data['points']&.size || 0} famílias)"
end

targets = ARGV.map do |arg|
  File.directory?(arg) ? File.join(arg, 'palette.yaml') : arg
end

targets = ['design/v6/palette.yaml'] if targets.empty?

root = File.expand_path('../../..', __dir__)
targets.each do |t|
  path = File.expand_path(t, root)
  if File.exist?(path)
    generate(path)
  else
    warn "Arquivo não encontrado: #{path}"
  end
end
