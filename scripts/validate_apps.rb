#!/usr/bin/env ruby
require_relative 'core/icon_preprocessor'

# ANSI color codes
RED   = "\e[31m"
DIM   = "\e[2m"
RESET = "\e[0m"

# Valid IDs
VALID_IDS = %w[em art bg ds]

failed_count = 0

IconPreprocessor.each do |tracker, ds_files|
  errors = []

  # 1. Root structure check
  invalid_root = tracker.matches_in([], :any) do |node|
    !%w[rect g].include?(node.name) || !VALID_IDS.include?(node['id'])
  end
  errors << "invalid root structure" unless invalid_root.empty?

  # 2. SVG dimensions and viewBox
  unless tracker.has_size?(64, 64) && !tracker.scaled?
    errors << "svg must have viewBox=\"0 0 64 64\" width=\"64\" height=\"64\""
  end

  # 3. bg element attributes
  bg = tracker.match_in([], :any, id: 'bg')
  if bg.nil?
    errors << "missing element with id=\"bg\""
  else
    bg_errors = []
    bg_errors << "x must be \"4.5\""             unless bg['x']      == '4.5'
    bg_errors << "y must be \"4.5\""             unless bg['y']      == '4.5'
    bg_errors << "width must be \"55\""          unless bg['width']  == '55'
    bg_errors << "height must be \"55\""         unless bg['height'] == '55'
    bg_errors << "rx must be \"10\" or \"27.5\"" unless %w[10 27.5].include?(bg['rx'])
    errors.concat(bg_errors.map { |e| "bg: #{e}" })
  end

  # 4. ds element matches template
  ds = tracker.match_in([], :any, id: 'ds')
  if ds.nil?
    errors << "missing element with id=\"ds\""
  elsif bg && %w[10 27.5].include?(bg['rx'])
    template_path = bg['rx'] == '10' ? ds_files.ds_square : ds_files.ds_round

    unless tracker.merged_equal?(ds, template_path, 'ds')
      errors << "ds: does not match template (#{File.basename(template_path)})"
    end
  end

  # Output
  unless errors.empty?
    puts "#{RED}✗#{RESET} #{File.basename(tracker.file_path)}"
    errors.each { |e| puts "  #{DIM}·#{RESET} #{e}" }
    failed_count += 1
  end
end

puts "\nValidation complete. #{failed_count} file(s) failed."