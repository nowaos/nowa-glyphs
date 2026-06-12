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

require_relative '../../core/icon_preprocessor'

ROOT      = File.expand_path('../../..', __dir__)
dry_run   = ARGV.include?('--dry-run')
apply     = !dry_run
issues_count = 0

IconPreprocessor.each(summary: apply, abort_if_versioned: apply) do |builder, tracker|
  meta      = tracker.metadata_nodes
  unused    = tracker.unused_def_nodes
  oob       = tracker.outside_viewbox_nodes
  ink_nodes = tracker.inkscape_nodes
  ink_attrs = tracker.inkscape_attr_count
  next if meta.empty? && unused.empty? && oob.empty? && ink_nodes.empty? && ink_attrs.zero?

  puts tracker.path.delete_prefix("#{ROOT}/")
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
  builder.create_version(indent: true)
end

puts "\n#{dry_run ? '[dry-run] ' : ''}#{issues_count} file(s) with issues." if dry_run && issues_count > 0
puts 'All clean.'                                                            if dry_run && issues_count.zero?
