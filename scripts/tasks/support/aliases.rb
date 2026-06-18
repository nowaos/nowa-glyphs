#!/usr/bin/env ruby
# Lists symlink names in links/ whose target matches the given filename(s).
#
# Usage:
#   rake support:aliases -- torBrowser.svg
#   rake support:aliases -- browser-tor.svg midori.svg

root       = File.expand_path('../../..', __dir__)
links_root = File.join(root, 'links')

ARGV.delete('--')
targets = ARGV
abort "Usage: rake support:aliases -- <filename.svg> [<filename.svg> ...]" if targets.empty?

targets.each do |target|
  target = File.basename(target)
  matches = Dir.glob("#{links_root}/**/*").select do |path|
    File.symlink?(path) && File.basename(File.readlink(path)) == target
  end

  puts "=== #{target} ===" if targets.size > 1
  matches.empty? ? puts("(no aliases)") : matches.sort.each { |m| puts File.basename(m) }
  puts if targets.size > 1
end
