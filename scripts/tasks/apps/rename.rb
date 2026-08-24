#!/usr/bin/env ruby
# Renames an app icon in src/ and repoints its symlinks in links/.
#
# Renames src/apps/scalable/_<category>/<old_name>.svg, renames the matching
# links/apps/scalable/<old_name>/ directory, repoints every symlink inside it,
# and drops the symlink whose own name would collide with the new target.
#
# Usage:
#   rake apps:rename -- internet/uget-icon uget
#   rake apps:rename -- _internet/uget-icon.svg uget.svg

root = File.expand_path('../../..', __dir__)

ARGV.delete('--')
source, new_name = ARGV
if source.nil? || new_name.nil?
  abort 'Usage: rake apps:rename -- <category>/<old_name> <new_name>'
end

category, old_name = source.split('/', 2)
abort "Expected <category>/<old_name>, got: #{source}" if old_name.to_s.empty?

category = category.delete_prefix('_')
old_name = File.basename(old_name, '.svg')
new_name = File.basename(new_name, '.svg')
abort 'Old and new name are the same' if old_name == new_name

src_rel = File.join('src/apps/scalable', "_#{category}")
old_src = File.join(root, src_rel, "#{old_name}.svg")
new_src = File.join(root, src_rel, "#{new_name}.svg")

abort "Icon not found: #{File.join(src_rel, "#{old_name}.svg")}" unless File.file?(old_src)
abort "Already exists: #{File.join(src_rel, "#{new_name}.svg")}" if File.exist?(new_src)

links_rel     = 'links/apps/scalable'
old_links_dir = File.join(root, links_rel, old_name)
new_links_dir = File.join(root, links_rel, new_name)
has_links     = File.directory?(old_links_dir)

abort "Already exists: #{File.join(links_rel, new_name)}" if has_links && File.exist?(new_links_dir)

File.rename(old_src, new_src)
puts "renamed   #{src_rel}/#{old_name}.svg -> #{new_name}.svg"

unless has_links
  warn "no links directory for #{old_name}, nothing else to do"
  exit
end

File.rename(old_links_dir, new_links_dir)
puts "renamed   #{links_rel}/#{old_name}/ -> #{new_name}/"

collision = File.join(new_links_dir, "#{new_name}.svg")
if File.symlink?(collision)
  File.delete(collision)
  puts "removed   #{new_name}/#{new_name}.svg"
end

Dir.children(new_links_dir).sort.each do |entry|
  path = File.join(new_links_dir, entry)
  next unless File.symlink?(path)
  next unless File.basename(File.readlink(path)) == "#{old_name}.svg"

  File.delete(path)
  File.symlink("#{new_name}.svg", path)
  puts "repointed #{new_name}/#{entry} -> #{new_name}.svg"
end
