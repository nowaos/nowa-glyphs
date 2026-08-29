# Cleans SVG files: removes metadata, unused defs, and editor artifacts.
#
# Cleans:
#   - Metadata elements (<title>, <desc>, <metadata>)
#   - Unused <defs> (gradients, filters, etc.)
#   - Shapes outside the viewBox (approximate — absolute M/L/H/V coords only for <path>)
#   - Inkscape/Sodipodi editor artifacts (namedview, inkscape:* attrs, etc.)
#
# Usage:
#   rake fix:normalize_svg                                                      # clean all src/apps/scalable/
#   rake fix:normalize_svg sandbox                                              # specific directory
#   rake fix:normalize_svg src/apps/scalable/gnome-core/org.gnome.Music.svg
#   rake fix:normalize_svg src/apps/scalable/gnome-core/org.gnome.Music.svg --dry-run
#   rake fix:normalize_svg src/apps/scalable/gnome-core/org.gnome.Music.svg --multiline

require_relative '../../core/cli'
require_relative '../../core/paths'
require_relative '../../core/sources'
require_relative '../../core/version'
require_relative '../../lib/svg_tracker'

cli     = Cli.parse(ARGV, flags: %i[dry_run multiline], values: %i[v tag])
dry_run = cli.dry_run?
files   = Sources.resolve(cli.path, fallback: Paths::SRC).reject_symlinks!

unless dry_run
  adding = cli.value(:v) || cli.value(:tag)
  adding ? files.reject_versions! : Version.assert_clean!(files.to_a)
end

issues_count = 0
created      = 0

files.each do |path|
  tracker   = SvgTracker.new(path)
  meta      = tracker.metadata_nodes
  unused    = tracker.unused_def_nodes
  oob       = tracker.outside_viewbox_nodes
  ink_nodes = tracker.inkscape_nodes
  ink_attrs = tracker.inkscape_attr_count
  next if meta.empty? && unused.empty? && oob.empty? && ink_nodes.empty? && ink_attrs.zero?

  puts Paths.relative(path)
  puts "  ✗ metadata: #{meta.map(&:name).join(', ')}"                                                             unless meta.empty?
  puts "  ✗ unused defs: #{unused.map { |n| [n.name, n['id']].compact.join('#') }.join(', ')}"                   unless unused.empty?
  puts "  ✗ outside viewBox: #{oob.map { |n| n['id'] ? "<#{n.name} ##{n['id']}>" : "<#{n.name}>" }.join(', ')}" unless oob.empty?
  unless ink_nodes.empty? && ink_attrs.zero?
    parts = []
    parts << ink_nodes.map { |n| "<#{n.namespace&.prefix}:#{n.name}>" }.join(', ') unless ink_nodes.empty?
    parts << "#{ink_attrs} attr(s)" unless ink_attrs.zero?
    puts "  ✗ inkscape: #{parts.join(', ')}"
  end
  issues_count += 1

  next if dry_run

  tracker.clean_metadata!
  tracker.clean_defs!
  tracker.clean_inkscape!
  oob.each(&:remove)
  tracker.save(Version.dest(path, tag: cli.value(:tag), n: cli.value(:v)&.to_i), indent: true, multiline: cli.multiline?)
  created += 1
end

if dry_run
  puts "\n[dry-run] #{issues_count} file(s) with issues." if issues_count > 0
  puts 'All clean.'                                       if issues_count.zero?
else
  puts "Done. #{created} file(s) processed."
end
