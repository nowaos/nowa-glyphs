require_relative '../test_helper'

LINKS_DIR = File.join(ROOT, 'links') unless defined?(LINKS_DIR)
SRC_DIR   = File.join(ROOT, 'src')

describe 'links/' do
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
