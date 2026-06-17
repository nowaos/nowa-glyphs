require_relative '../test_helper'

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
end
