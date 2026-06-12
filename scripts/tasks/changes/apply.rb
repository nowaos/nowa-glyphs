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

ROOT = File.expand_path('../../..', __dir__)

argv    = ARGV.dup
v_idx   = argv.index('-v')
force_v = if v_idx
  val = argv.delete_at(v_idx + 1)&.to_i
  argv.delete_at(v_idx)
  val
end
dry_run = argv.delete('--dry-run')
arg     = argv.reject { |a| a.start_with?('-') }.first

abort 'Error: path argument required (file or directory)' unless arg

target = File.join(ROOT, arg)
abort "Error: '#{arg}' not found" unless File.exist?(target)

pattern = if File.file?(target)
  target.sub(/\.svg\z/, '') + '.v*.svg'
else
  File.join(target, '**', '*.svg')
end

versioned = Dir.glob(pattern).select { |f| File.basename(f).match?(/\.v\d+\.svg\z/) }

groups = versioned.group_by { |f|
  base = File.basename(f, '.svg').sub(/\.v\d+\z/, '')
  File.join(File.dirname(f), "#{base}.svg")
}

if groups.empty?
  puts 'Nothing to apply.'
  exit
end

conflicts = groups.select { |_, versions| versions.size > 1 }

if conflicts.any? && !force_v
  puts "Error: multiple versions exist — pass -v N to choose which to apply:"
  conflicts.each do |orig, versions|
    sorted = versions.sort_by { |f| File.basename(f, '.svg').match(/\.v(\d+)\z/)[1].to_i }
    puts "  #{orig.delete_prefix("#{ROOT}/")}:"
    sorted.each { |f| puts "    #{f.delete_prefix("#{ROOT}/")}" }
  end
  exit 1
end

promoted = 0

groups.each do |orig, versions|
  unless File.exist?(orig)
    warn "Warning: original not found for #{File.basename(versions.first)}, skipping."
    next
  end

  sorted = versions.sort_by { |f| File.basename(f, '.svg').match(/\.v(\d+)\z/)[1].to_i }

  chosen = if sorted.size == 1
    sorted.first
  else
    match = sorted.find { |f| File.basename(f, '.svg').end_with?(".v#{force_v}") }
    unless match
      warn "Warning: v#{force_v} not found for #{File.basename(orig)}, skipping."
      next
    end
    match
  end

  rel_orig   = orig.delete_prefix("#{ROOT}/")
  rel_chosen = chosen.delete_prefix("#{ROOT}/")

  if dry_run
    puts "[dry-run] #{rel_chosen} → #{rel_orig}"
    sorted.each { |v| puts "[dry-run] delete #{v.delete_prefix("#{ROOT}/")}" }
  else
    FileUtils.cp(chosen, orig)
    sorted.each { |v| FileUtils.rm(v) }
    puts "✓ #{File.basename(chosen)} → #{File.basename(orig)}"
    promoted += 1
  end
end

puts "\nDone. #{promoted} file(s) promoted." unless dry_run
