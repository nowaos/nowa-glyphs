require_relative '../test_helper'

describe 'fix:normalize_svg' do
  include TestHelper
  let(:script) { 'tasks/fix/normalize_svg.rb' }

  it 'should create a versioned file' do
    path = copy_fixture('dirty.svg')

    run_script(script, path)

    assert File.exist?(abs(versioned(path)))
  end

  it 'should remove metadata' do
    path = copy_fixture('dirty.svg')

    run_script(script, path)

    refute_match(/<title[\s>]|<desc[\s>]/, File.read(abs(versioned(path))))
  end

  it 'should remove unused defs' do
    path = copy_fixture('dirty.svg')

    run_script(script, path)

    refute_match(/unused_grad/, File.read(abs(versioned(path))))
  end

  it 'should remove inkscape elements' do
    path = copy_fixture('dirty-inskscape.svg')

    run_script(script, path)

    refute_match(/sodipodi:namedview/, File.read(abs(versioned(path))))
  end

  it 'should remove inkscape attrs' do
    path = copy_fixture('dirty-inskscape.svg')

    run_script(script, path)

    content = File.read(abs(versioned(path)))
    refute_match(/inkscape:collect/, content)
    refute_match(/inkscape:version/, content)
    refute_match(/sodipodi:docname/, content)
  end

  it 'should strip unused editor xmlns' do
    path = copy_fixture('dirty-inskscape.svg')

    run_script(script, path)

    content = File.read(abs(versioned(path)))
    refute_match(/xmlns:inkscape/, content)
    refute_match(/xmlns:sodipodi/, content)
  end

  it 'should preserve xmlns:xlink when used' do
    path = copy_fixture('dirty-inskscape.svg')

    run_script(script, path)

    assert_match(/xmlns:xlink/, File.read(abs(versioned(path))))
  end

  it 'should remove blank lines' do
    path = copy_fixture('dirty-inskscape.svg')

    run_script(script, path)

    refute_match(/\n\s*\n/, File.read(abs(versioned(path))))
  end

  it 'should print summary' do
    path = copy_fixture('dirty.svg')

    out, _ = run_script(script, path)

    assert_match(/Done\. 1 file\(s\) processed\./, out)
  end

  it 'should skip clean icons' do
    path = copy_fixture('square.svg')

    run_script(script, path)

    refute File.exist?(abs(versioned(path)))
  end

  describe 'with --dry-run' do
    it 'should not create a versioned file' do
      path = copy_fixture('dirty.svg')

      run_script(script, path, '--dry-run')

      refute File.exist?(abs(versioned(path)))
    end

    it 'should report metadata and unused defs' do
      path = copy_fixture('dirty.svg')

      out, _ = run_script(script, path, '--dry-run')

      assert_match(/metadata: title, desc/, out)
      assert_match(/unused defs: linearGradient#unused_grad/, out)
    end

    it 'should report all clean for a clean icon' do
      path = copy_fixture('square.svg')

      out, _ = run_script(script, path, '--dry-run')

      assert_match(/All clean\./, out)
    end

    it 'should report issue count' do
      path = copy_fixture('dirty.svg')

      out, _ = run_script(script, path, '--dry-run')

      assert_match(/1 file\(s\) with issues\./, out)
    end

    it 'should detect inkscape artifacts' do
      path = copy_fixture('dirty-inskscape.svg')

      out, _ = run_script(script, path, '--dry-run')

      assert_match(/inkscape:/, out)
    end
  end
end
