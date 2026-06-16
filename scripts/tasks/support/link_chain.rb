#!/usr/bin/env ruby
# Prints the alias chain for a symlink or all symlinks in a directory.
#
# Usage:
#   rake support:link_chain links/apps/scalable/google-calculator/chrome-calculator.svg
#   rake support:link_chain links/apps/scalable/google-calculator

require 'set'

root       = File.expand_path('../../..', __dir__)
links_root = File.join(root, 'links')

target = ARGV.first
abort "Usage: rake support:link_chain <path>" unless target

path = File.expand_path(target, root)
abort "Path not found: #{path}" unless File.exist?(path) || File.symlink?(path)

def size_dir(path, links_root)
  rel   = path.delete_prefix(links_root + '/')
  parts = rel.split('/')
  File.join(links_root, parts[0], parts[1])
end

def build_map(dir)
  map = {}
  Dir.glob("#{dir}/**/*").select { |p| File.symlink?(p) }.each do |p|
    map[File.basename(p, '.svg')] = File.basename(File.dirname(p))
  end
  map
end

def resolve_chain(start_alias, map)
  chain   = [start_alias]
  current = start_alias
  seen    = Set.new([current])
  while map.key?(current)
    nxt = map[current]
    break if seen.include?(nxt)
    seen << nxt
    chain << nxt
    current = nxt
  end
  chain
end

symlinks = File.symlink?(path) ? [path] : Dir.glob("#{path}/**/*").select { |p| File.symlink?(p) }

symlinks.each do |sym|
  map   = build_map(size_dir(sym, links_root))
  chain = resolve_chain(File.basename(sym, '.svg'), map)
  chain[-1] = "#{chain.last}.svg"
  puts chain.join(' -> ')
end
