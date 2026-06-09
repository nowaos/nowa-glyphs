# Promotes versioned files (.vN) back to their originals.
# If one vN exists → promotes automatically.
# If multiple vN exist for the same file → asks which to apply.
# Tagged files (-tag.svg) are left untouched.
# After running, no .vN files remain in the target area.
#
# Usage:
#   ruby scripts/autofix/apply_changes.rb <path>           # file or directory (relative to root)
#   ruby scripts/autofix/apply_changes.rb <path> --dry-run # preview without applying

require 'fileutils'

ROOT    = File.expand_path('../..', __dir__)
dry_run = ARGV.include?('--dry-run')

arg = ARGV.reject { |a| a.start_with?('-') }.first
abort 'Error: path argument required (file or directory)' unless arg

target = File.join(ROOT, arg)
abort "Error: '#{arg}' not found" unless File.exist?(target)

pattern = if File.file?(target)
  target.sub(/\.svg\z/, '') + '.v*.svg'
else
  File.join(target, '**', '*.svg')
end

# Collect all .vN files in scope, group by original path
versioned = Dir.glob(pattern).select { |f| File.basename(f).match?(/\.v\d+\.svg\z/) }

groups = versioned.group_by { |f|
  base = File.basename(f, '.svg').sub(/\.v\d+\z/, '')
  File.join(File.dirname(f), "#{base}.svg")
}

if groups.empty?
  puts 'Nothing to apply.'
  exit
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
    rel = orig.delete_prefix("#{ROOT}/")
    puts "\nMultiple versions for #{rel}:"
    sorted.each_with_index { |v, i| puts "  [#{i + 1}] #{File.basename(v)}" }
    print "  Which to apply? (1–#{sorted.size}, default #{sorted.size}): "
    input = $stdin.gets&.chomp.to_i
    input = sorted.size if input < 1 || input > sorted.size
    sorted[input - 1]
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
