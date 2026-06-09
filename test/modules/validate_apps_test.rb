require_relative '../test_helper'

describe 'validate_apps' do
  include TestHelper
  let(:script) { 'validate_apps.rb' }

  it 'should pass for valid square icon' do
    path = copy_fixture('square.svg')

    out, _ = run_script(script, path)

    refute_match(/✗/, out)
  end

  it 'should pass for valid round icon' do
    path = copy_fixture('round.svg')

    out, _ = run_script(script, path)

    refute_match(/✗/, out)
  end

  it 'should print summary line' do
    path = copy_fixture('square.svg')

    out, _ = run_script(script, path)

    assert_match(/Validation complete\./, out)
  end

  describe 'when icon has errors' do
    it 'should fail for wrong bg rx' do
      path = copy_fixture('square.svg')
      File.write(abs(path), File.read(abs(path)).sub('rx="10"', 'rx="5"'))

      out, _ = run_script(script, path)

      assert_match(/rx must be/, out)
    end

    it 'should fail for missing bg' do
      path = copy_fixture('square.svg')
      File.write(abs(path), File.read(abs(path)).gsub('id="bg"', 'id="background"'))

      out, _ = run_script(script, path)

      assert_match(/missing element with id="bg"/, out)
    end

    it 'should fail for wrong canvas size' do
      path = copy_fixture('square.svg')
      File.write(abs(path), File.read(abs(path)).sub('width="64"', 'width="48"').sub('height="64"', 'height="48"'))

      out, _ = run_script(script, path)

      assert_match(/viewBox/, out)
    end
  end
end
