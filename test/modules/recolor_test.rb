require_relative '../test_helper'

describe 'recolor' do
  include TestHelper
  let(:script) { 'autofix/recolor.rb' }

  it 'should create a version for off-palette icon' do
    path = copy_fixture('dirty.svg')

    run_script(script, path)

    assert File.exist?(abs(versioned(path)))
  end

  it 'should remap off-palette color' do
    path = copy_fixture('dirty.svg')

    run_script(script, path)

    refute_match(/#1a2b3c/i, File.read(abs(versioned(path))))
  end

  it 'should print summary' do
    path = copy_fixture('dirty.svg')

    out, _ = run_script(script, path)

    assert_match(/Done\./, out)
  end

  it 'should create a version with --non-apps' do
    path = copy_fixture('dirty.svg')

    run_script(script, path, '--non-apps')

    assert File.exist?(abs(versioned(path)))
  end

  it 'should not crash for icon with no colors to remap' do
    path = copy_fixture('square.svg')

    _, status = run_script(script, path)

    assert status.success?
  end
end
