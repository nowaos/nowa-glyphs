# Removes all versioned files (.vN) from the target area, keeping only originals.
# Tagged files (-tag.svg) are left untouched.
#
# Usage:
#   rake changes:undo <path>           # file or directory (relative to root)
#   rake changes:undo <path> --dry-run # preview only

require 'fileutils'

ROOT    = File.expand_path('../../..', __dir__)
dry_run = ARGV.include?('--dry-run')

arg = ARGV.reject { |a| a.start_with?('-') }.first
abort 'Error: path argument required (file or directory)' unless arg

target = File.join(ROOT, arg)
abort "Error: '#{arg}' not found" unless File.exist?(target)

pattern = File.directory?(target) ? File.join(target, '**', '*.svg') : target

versioned = Dir.glob(pattern).select { |f| File.basename(f).match?(/\.v\d+\.svg\z/) }

if versioned.empty?
  puts 'Nothing to undo.'
  exit
end

versioned.each do |f|
  rel = f.delete_prefix("#{ROOT}/")
  if dry_run
    puts "[dry-run] delete #{rel}"
  else
    FileUtils.rm(f)
    puts "✗ #{rel}"
  end
end

puts "\n#{dry_run ? '[dry-run] ' : ''}#{versioned.size} versioned file(s) removed."
