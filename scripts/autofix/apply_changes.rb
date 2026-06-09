# Promotes versioned files (.vN) back to their originals.
# If one vN exists → promotes automatically.
# If multiple vN exist for the same file → asks which to apply.
# Tagged files (-tag.svg) are left untouched.
# After running, no .vN files remain in the target area.
#
# Usage:
#   ruby scripts/autofix/apply_changes.rb                          # all src/apps/scalable/
#   ruby scripts/autofix/apply_changes.rb -d test                  # specific directory
#   ruby scripts/autofix/apply_changes.rb -f org.gnome.Music.svg   # specific file
#   ruby scripts/autofix/apply_changes.rb --dry-run                # preview without applying

require 'fileutils'

ROOT    = File.expand_path('../..', __dir__)
dry_run = ARGV.include?('--dry-run')

directory = nil
filename  = nil
ARGV.each_with_index do |arg, i|
  directory = ARGV[i + 1] if arg == '-d'
  filename  = ARGV[i + 1] if arg == '-f'
end

pattern = if directory
  File.join(ROOT, directory, '*.svg')
elsif filename&.include?(File::SEPARATOR)
  File.join(ROOT, filename.sub(/\.svg\z/, '') + '.v*.svg')
else
  File.join(ROOT, 'src', 'apps', 'scalable', '**', '*.svg')
end

# Collect all .vN files in scope, group by original path
versioned = Dir.glob(pattern).select { |f| File.basename(f).match?(/\.v\d+\.svg\z/) }

if filename && !filename.include?(File::SEPARATOR)
  versioned = versioned.select { |f|
    File.basename(f, '.svg').sub(/\.v\d+\z/, '') + '.svg' == filename
  }
end

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
