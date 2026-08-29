# Removes all versioned files (.vN) from the target area, keeping only originals.
# Tagged files (-tag.svg) are left untouched.
#
# Usage:
#   rake changes:undo <path>           # file or directory (relative to root)
#   rake changes:undo <path> --dry-run # preview only

require 'fileutils'
require_relative '../../core/cli'
require_relative '../../core/paths'
require_relative '../../core/version'

cli = Cli.parse(ARGV, flags: %i[dry_run])
abort 'Error: path argument required (file or directory)' unless cli.path

target = Paths.absolute(cli.path)
abort "Error: '#{cli.path}' not found" unless File.exist?(target)

versioned = Version.list_in(target)

if versioned.empty?
  puts 'Nothing to undo.'
  exit
end

versioned.each do |f|
  rel = Paths.relative(f)
  if cli.dry_run?
    puts "[dry-run] delete #{rel}"
  else
    FileUtils.rm(f)
    puts "✗ #{rel}"
  end
end

puts "\n#{cli.dry_run? ? '[dry-run] ' : ''}#{versioned.size} versioned file(s) removed."
