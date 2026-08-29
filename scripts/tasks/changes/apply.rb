# Promotes versioned files (.vN) back to their originals.
# If one vN exists → promotes automatically.
# If multiple vN exist for the same file → aborts unless -v N is passed.
# Tagged files (-tag.svg) are left untouched.
# After running, no .vN files remain in the target area.
#
# Usage:
#   rake changes:apply <path>           # file or directory (relative to root)
#   rake changes:apply <path> --dry-run # preview without applying
#   rake changes:apply <path> -v 2      # apply a specific version when multiple exist

require 'fileutils'
require_relative '../../core/cli'
require_relative '../../core/paths'
require_relative '../../core/version'

cli     = Cli.parse(ARGV, flags: %i[dry_run], values: %i[v])
force_v = cli.value(:v)&.to_i
abort 'Error: path argument required (file or directory)' unless cli.path

target = Paths.absolute(cli.path)
abort "Error: '#{cli.path}' not found" unless File.exist?(target)

groups = Version.groups_in(target)

if groups.empty?
  puts 'Nothing to apply.'
  exit
end

conflicts = groups.select { |_, versions| versions.size > 1 }

if conflicts.any? && !force_v
  puts 'Error: multiple versions exist — pass -v N to choose which to apply:'
  conflicts.each do |orig, versions|
    puts "  #{Paths.relative(orig)}:"
    versions.each { |f| puts "    #{Paths.relative(f)}" }
  end
  exit 1
end

promoted = 0

groups.each do |orig, versions|
  unless File.exist?(orig)
    warn "Warning: original not found for #{File.basename(versions.first)}, skipping."
    next
  end

  chosen =
    if versions.size == 1
      versions.first
    else
      match = versions.find { |f| Version.number_of(f) == force_v }
      unless match
        warn "Warning: v#{force_v} not found for #{File.basename(orig)}, skipping."
        next
      end
      match
    end

  if cli.dry_run?
    puts "[dry-run] #{Paths.relative(chosen)} → #{Paths.relative(orig)}"
    versions.each { |v| puts "[dry-run] delete #{Paths.relative(v)}" }
  else
    FileUtils.cp(chosen, orig)
    versions.each { |v| FileUtils.rm(v) }
    puts "✓ #{File.basename(chosen)} → #{File.basename(orig)}"
    promoted += 1
  end
end

puts "\nDone. #{promoted} file(s) promoted." unless cli.dry_run?
