#!/usr/bin/env ruby
# Lists symlink names in links/ whose target matches the given filename(s).
#
# With --add, creates the given aliases pointing at a single icon instead.
# The .svg suffix is optional everywhere.
#
# Usage:
#   rake links:aliases -- torBrowser.svg
#   rake links:aliases -- browser-tor.svg midori.svg
#   rake links:aliases -- protonvpn-logo --add com.protonvpn.www
#   rake links:aliases -- protonvpn-logo --add com.protonvpn.www protonvpn.svg

require 'fileutils'

root       = File.expand_path('../../..', __dir__)
links_root = File.join(root, 'links')
apps_root  = File.join(links_root, 'apps', 'scalable')

ARGV.delete('--')

USAGE = <<~TXT
  Usage: rake links:aliases -- <filename.svg> [<filename.svg> ...]
         rake links:aliases -- <icon> --add <alias> [<alias> ...]
TXT

svg = ->(name) { "#{File.basename(name.to_s, '.svg')}.svg" }

aliases_of = lambda do |target|
  Dir.glob("#{links_root}/**/*").select do |path|
    File.symlink?(path) && File.basename(File.readlink(path)) == target
  end
end

split     = ARGV.index('--add')
targets   = split ? ARGV[0...split] : ARGV
new_names = split ? ARGV[(split + 1)..].to_a : nil

abort USAGE if targets.empty? || (new_names && new_names.empty?)

# --- create mode -----------------------------------------------------------
if new_names
  abort "--add takes a single icon, got #{targets.size}" unless targets.size == 1

  icon = File.basename(targets.first, '.svg')
  abort "Icon not found in src/apps/scalable: #{icon}.svg" if
    Dir.glob(File.join(root, 'src/apps/scalable/_*', "#{icon}.svg")).empty?

  # The icon name must not already be an alias elsewhere, nor may a new alias
  # name already be an alias directory — either way we'd build a chain
  # (alias -> icon -> other). See test/links/chained_links_test.rb.
  named = Dir.glob("#{links_root}/**/*").select do |p|
    File.symlink?(p) && File.basename(p) == svg.(icon)
  end
  unless named.empty?
    dirs = named.map { |p| File.basename(File.dirname(p)) }.uniq.join(', ')
    abort "Would chain: '#{svg.(icon)}' already exists as an alias under #{dirs}"
  end

  new_names.each do |name|
    base = File.basename(name, '.svg')
    abort "Would chain: '#{base}' is already an alias directory" if
      File.directory?(File.join(apps_root, base))
  end

  dir = File.join(apps_root, icon)
  FileUtils.mkdir_p(dir)

  new_names.each do |name|
    link = File.join(dir, svg.(name))
    if File.symlink?(link) || File.exist?(link)
      puts "exists   #{icon}/#{svg.(name)}"
      next
    end
    File.symlink(svg.(icon), link)
    puts "created  #{icon}/#{svg.(name)} -> #{svg.(icon)}"
  end
  exit
end

# --- list mode -------------------------------------------------------------
targets.each do |target|
  target  = svg.(target)
  matches = aliases_of.(target)

  puts "=== #{target} ===" if targets.size > 1
  matches.empty? ? puts('(no aliases)') : matches.sort.each { |m| puts File.basename(m) }
  puts if targets.size > 1
end
