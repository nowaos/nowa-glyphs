require_relative '../test_helper'

LINKS_DIR = File.join(ROOT, 'links') unless defined?(LINKS_DIR)

describe 'links/' do
  it 'has no chained symlinks (alias pointing to another alias)' do
    all_symlinks = Dir.glob("#{LINKS_DIR}/**/*").select { |p| File.symlink?(p) }

    target_dirs = all_symlinks.map { |p| File.basename(File.dirname(p)) }.to_set

    chained_dir_names = all_symlinks
      .select { |p| target_dirs.include?(File.basename(p, '.svg')) }
      .map    { |p| File.basename(p, '.svg') }
      .to_set

    broken = all_symlinks.select { |p| chained_dir_names.include?(File.basename(File.dirname(p))) }

    assert broken.empty?, "Symlinks inside chained (intermediate) dirs:\n" +
      broken.map { |p| "- #{p.delete_prefix(ROOT + '/')} -> #{File.readlink(p)}" }.sort.join("\n")
  end
end
