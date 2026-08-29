#!/usr/bin/env ruby
# Creates or updates a throwaway .desktop launcher that previews the icon at <path>.
#
# Writes ~/.local/share/applications/nowa-glyphs-preview.desktop with its Icon=
# pointing straight at <path>, then refreshes the icon cache of the locally
# installed theme and the desktop database so menus pick the change up.
# Pass --rm to delete the launcher again.
#
# Usage:
#   rake apps:preview -- src/apps/scalable/_internet/uget.svg
#   rake apps:preview -- --rm

require 'fileutils'

ROOT         = File.expand_path('../../..', __dir__)
HOME         = Dir.home
APPS_DIR     = File.join(HOME, '.local', 'share', 'applications')
THEME_DIR    = File.join(HOME, '.local', 'share', 'icons', 'Nowa Glyphs')
DESKTOP_FILE = File.join(APPS_DIR, 'nowa-glyphs-preview.desktop')

def short(path) = path.start_with?(HOME) ? path.sub(HOME, '~') : path

def refresh_caches
  if File.directory?(THEME_DIR)
    system('gtk-update-icon-cache', '-f', '-t', THEME_DIR, %i[out err] => File::NULL)
    system('gtk4-update-icon-cache', '-f', '-t', THEME_DIR, %i[out err] => File::NULL)
  end
  system('update-desktop-database', APPS_DIR, %i[out err] => File::NULL)
end

args   = ARGV.reject { |a| a == '--' }
remove = args.delete('--rm')

if remove
  if File.exist?(DESKTOP_FILE)
    File.delete(DESKTOP_FILE)
    puts "removed   #{short(DESKTOP_FILE)}"
  else
    puts "absent    #{short(DESKTOP_FILE)}"
  end
  refresh_caches
  exit
end

rel = args.first
abort 'Usage: rake apps:preview -- <path>  |  rake apps:preview -- --rm' unless rel
abort "Error: unexpected extra argument '#{args[1]}'" if args.size > 1

icon = File.absolute_path?(rel) ? rel : File.join(ROOT, rel)
abort "Error: not found: #{rel}"  unless File.file?(icon)
abort "Error: not an SVG: #{rel}" unless File.extname(icon).casecmp?('.svg')

FileUtils.mkdir_p(APPS_DIR)
File.write(DESKTOP_FILE, <<~DESKTOP)
  [Desktop Entry]
  Type=Application
  Name=Preview
  Comment=Preview of #{rel}
  Exec=true
  Icon=#{icon}
  Terminal=false
  NoDisplay=false
  Categories=Utility;
DESKTOP

puts "wrote     #{short(DESKTOP_FILE)}"
puts "icon      #{short(icon)}"
warn "warning: theme not installed at #{short(THEME_DIR)} — run ./install.sh" unless File.directory?(THEME_DIR)
refresh_caches
