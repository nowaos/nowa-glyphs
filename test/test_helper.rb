require 'minitest/autorun'
require 'open3'
require 'fileutils'

ROOT     = File.expand_path('..', __dir__)
FIXTURES = File.join(ROOT, 'test', 'fixtures')
TMP_DIR  = File.join(ROOT, 'test', 'tmp')

module TestHelper
  def setup
    @tmp_bases = []
    super
  end

  def teardown
    @tmp_bases.each do |base|
      Dir.glob("#{base}*.svg").each { |f| File.delete(f) }
    end
    super
  end

  def run_script(script, *args)
    Open3.capture2('ruby', File.join(ROOT, 'scripts', script), *args, chdir: ROOT)
  end

  # Copies a fixture to tmp/ and returns its path relative to ROOT.
  def copy_fixture(name)
    base     = File.basename(name, '.svg')
    rel      = "test/tmp/#{base}_#{object_id}.svg"
    abs_path = File.join(ROOT, rel)
    
    FileUtils.cp(File.join(FIXTURES, name), abs_path)
    @tmp_bases << abs_path.sub(/\.svg\z/, '')
    rel
  end

  def abs(rel)
    File.join(ROOT, rel)
  end

  def versioned(rel, n = 2)
    rel.sub(/\.svg\z/, ".v#{n}.svg")
  end
end
