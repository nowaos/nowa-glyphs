# Removes all versioned files (.vN) from the target area, keeping only originals.
# Tagged files (-tag.svg) are left untouched.
#
# Usage:
#   ruby scripts/autofix/undo_changes.rb                  # all src/apps/scalable/
#   ruby scripts/autofix/undo_changes.rb -d test           # specific directory
#   ruby scripts/autofix/undo_changes.rb -d test --dry-run # preview only

require 'fileutils'

ROOT    = File.expand_path('../..', __dir__)
dry_run = ARGV.include?('--dry-run')

directory = nil
ARGV.each_with_index { |arg, i| directory = ARGV[i + 1] if arg == '-d' }

pattern = directory ? File.join(ROOT, directory, '*.svg') : File.join(ROOT, 'src', 'apps', 'scalable', '**', '*.svg')

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
