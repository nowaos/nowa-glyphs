#!/usr/bin/env ruby
# Creates or updates throwaway .desktop launchers that preview an icon at <path>.
#
# Each preview occupies a numbered slot (default 1), so two versions can sit
# side by side in the menu. Writes
# ~/.local/share/applications/nowa-glyphs-preview-<N>.desktop with its Icon=
# pointing straight at <path>, then refreshes the icon cache of the locally
# installed theme and the desktop database so menus pick the change up.
#
# Usage:
#   rake apps:preview -- src/apps/scalable/_internet/uget.svg      # slot 1
#   rake apps:preview -- src/apps/scalable/_internet/uget.svg 2    # slot 2
#   rake apps:preview -- --rm                                      # remove every slot
#   rake apps:preview -- --rm 2                                    # remove slot 2
#   rake apps:preview                                             # list active slots

require 'fileutils'

ROOT      = File.expand_path('../../..', __dir__)
HOME      = Dir.home
APPS_DIR  = File.join(HOME, '.local', 'share', 'applications')
THEME_DIR = File.join(HOME, '.local', 'share', 'icons', 'Nowa Glyphs')
SLOT_GLOB = File.join(APPS_DIR, 'nowa-glyphs-preview-*.desktop')

def short(path) = path.start_with?(HOME) ? path.sub(HOME, '~') : path

# Absolute path of a slot's launcher file.
def desktop_file(slot) = File.join(APPS_DIR, "nowa-glyphs-preview-#{slot}.desktop")

# Parses a slot argument, aborting when it is not a positive integer.
def slot_int(arg)
  abort "Error: slot must be a positive integer, got '#{arg}'" unless arg.to_s.match?(/\A[1-9]\d*\z/)

  arg.to_i
end

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
  abort "Error: unexpected extra argument '#{args[1]}'" if args.size > 1

  files = args.empty? ? Dir.glob(SLOT_GLOB).sort : [desktop_file(slot_int(args.first))]
  if files.empty?
    puts 'no previews to remove'
  else
    files.each do |file|
      if File.exist?(file)
        File.delete(file)
        puts "removed   #{short(file)}"
      else
        puts "absent    #{short(file)}"
      end
    end
  end
  refresh_caches
  exit
end

if args.empty?
  slots = Dir.glob(SLOT_GLOB).sort
  slots.empty? ? puts('no active previews') : slots.each { |f| puts short(f) }
  exit
end

rel, slot_arg = args
abort "Error: unexpected extra argument '#{args[2]}'" if args.size > 2
slot = slot_arg ? slot_int(slot_arg) : 1

icon = File.absolute_path?(rel) ? rel : File.join(ROOT, rel)
abort "Error: not found: #{rel}"  unless File.file?(icon)
abort "Error: not an SVG: #{rel}" unless File.extname(icon).casecmp?('.svg')

FileUtils.mkdir_p(APPS_DIR)
File.write(desktop_file(slot), <<~DESKTOP)
  [Desktop Entry]
  Type=Application
  Name=Preview #{slot}
  Comment=Preview of #{rel}
  Exec=true
  Icon=#{icon}
  Terminal=false
  NoDisplay=false
  Categories=Utility;
DESKTOP

puts "wrote     #{short(desktop_file(slot))}"
puts "icon      #{short(icon)}"
warn "warning: theme not installed at #{short(THEME_DIR)} — run ./install.sh" unless File.directory?(THEME_DIR)
refresh_caches
