require_relative '../test_helper'

LINKS_DIR = File.join(ROOT, 'links')
SRC_DIR   = File.join(ROOT, 'src')

describe 'links/' do
  it 'grouped symlinks point to a target matching their parent directory name' do
    violations = []

    Dir.glob("#{LINKS_DIR}/**/*").each do |path|
      next unless File.symlink?(path)

      parent  = File.basename(File.dirname(path))
      target  = File.basename(File.readlink(path), '.svg')

      violations << "#{path.delete_prefix(ROOT + '/')} -> #{File.readlink(path)}" if parent != target
    end

    assert_empty violations, "Symlinks where parent dir != target name:\n#{violations.join("\n")}"
  end

  it 'each target dir has a corresponding SVG in src/' do
    src_icons = Dir.glob("#{SRC_DIR}/**/*.svg").map { |f| File.basename(f, '.svg') }.to_set

    missing = Dir.glob("#{LINKS_DIR}/**/*")
      .select { |p| File.symlink?(p) }
      .map    { |p| File.basename(File.dirname(p)) }
      .uniq
      .reject { |name| src_icons.include?(name) }

    assert_empty missing, "Target dirs with no matching SVG in src/:\n#{missing.sort.join("\n")}"
  end
end
