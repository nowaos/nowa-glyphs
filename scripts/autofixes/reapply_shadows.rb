require_relative '../core/icon_preprocessor'

IconPreprocessor.update do |tracker, ds_files|
  ds = tracker.match_in([], :any, id: 'ds')
  ds&.remove

  tracker.clean_defs!

  bg = tracker.match_in([], :any, id: 'bg')
  template_path = bg['rx'] == '27.5' ? ds_files.ds_round : ds_files.ds_square

  tracker.merge!(template_path, position: :before)
end