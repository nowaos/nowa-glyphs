require_relative '../test_helper'

describe 'update_shadows' do
  include TestHelper
  let(:script) { 'autofix/update_shadows.rb' }

  it 'should create a versioned file for square icon' do
    path = copy_fixture('square.svg')

    run_script(script, path)

    assert File.exist?(abs(versioned(path)))
  end

  it 'should create a versioned file for round icon' do
    path = copy_fixture('round.svg')

    run_script(script, path)

    assert File.exist?(abs(versioned(path)))
  end

  it 'should match square ds template' do
    path = copy_fixture('square.svg')

    run_script(script, path)

    require_relative '../../scripts/lib/svg_tracker'
    t  = SvgTracker.new(abs(versioned(path)))
    ds = t.match_in([], :any, id: 'ds')
    assert t.merged_equal?(ds, File.join(ROOT, 'src/apps/templates/ds.svg'), 'ds')
  end

  it 'should match round ds template' do
    path = copy_fixture('round.svg')

    run_script(script, path)

    require_relative '../../scripts/lib/svg_tracker'
    t  = SvgTracker.new(abs(versioned(path)))
    ds = t.match_in([], :any, id: 'ds')
    assert t.merged_equal?(ds, File.join(ROOT, 'src/apps/templates/ds-round.svg'), 'ds')
  end

  it 'should print summary' do
    path = copy_fixture('square.svg')

    out, _ = run_script(script, path)

    assert_match(/Done\./, out)
  end
end
