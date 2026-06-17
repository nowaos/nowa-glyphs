require_relative '../test_helper'

describe 'links/' do
  it 'has no chained symlinks (alias pointing to another alias)' do
    all_symlinks = Dir.glob("#{LINKS_DIR}/**/*").select { |p| File.symlink?(p) }

    rel_dir = ->(p) {
      File.dirname(p).delete_prefix(LINKS_DIR + '/').split('/').map { |s| s.sub(/\A_/, '') }.join('/')
    }

    target_dir_paths = all_symlinks.map { |p| rel_dir.(p) }.to_set

    chained_dir_paths = all_symlinks.each_with_object(Set.new) do |p, set|
      parts  = rel_dir.(p).split('/')
      candidate = (parts[0..-2] + [File.basename(p, '.svg')]).join('/')
      set << candidate if target_dir_paths.include?(candidate)
    end

    broken = all_symlinks.select { |p| chained_dir_paths.include?(rel_dir.(p)) }

    assert broken.empty?, "Symlinks inside chained (intermediate) dirs:\n" +
      broken.map { |p| "- #{p.delete_prefix(ROOT + '/')} -> #{File.readlink(p)}" }.sort.join("\n")
  end
end
