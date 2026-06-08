require 'fileutils'
require 'ostruct'
require_relative '../lib/svg_tracker'

module IconPreprocessor
  class << self
    attr_reader :args

    def setup(argv = ARGV, base_dir: nil)
      @root      = File.expand_path(File.join(__dir__, '..', '..'))
      @base_dir  = base_dir || File.join(@root, 'src', 'apps')
      @input_dir = File.join(@base_dir, 'scalable')

      ds_square = File.join(@base_dir, 'templates', 'ds.svg')
      ds_round  = File.join(@base_dir, 'templates', 'ds-round.svg')
      @ds = OpenStruct.new(ds_square: ds_square, ds_round: ds_round)

      abort "Error: template not found: #{ds_square}" unless File.exist?(ds_square)
      abort "Error: template not found: #{ds_round}"  unless File.exist?(ds_round)

      filename  = nil
      directory = nil
      argv.each_with_index do |arg, i|
        filename  = argv[i + 1] if arg == '-f'
        directory = argv[i + 1] if arg == '-d'
      end

      @args = OpenStruct.new(
        filename:  filename,
        directory: directory,
        new:       argv.include?('--new')
      )
    end

    def update(&block)
      setup unless @args
      count = 0

      files_to_process.each do |file_path|
        tracker = SvgTracker.new(file_path)

        yield tracker, @ds

        tracker.save(next_version_path(file_path))
        count += 1
      end

      puts "Done. #{count} file(s) processed."
    end

    def each(&block)
      setup unless @args
      
      files_to_process.each do |file_path|
        tracker = SvgTracker.new(file_path)
        
        yield tracker, @ds
      end
    end

    private

    def next_version_path(path)
      dir  = File.dirname(path)
      base = File.basename(path, '.svg').sub(/\.v\d+\z/, '')
      existing = Dir.glob(File.join(dir, "#{base}.v*.svg"))
        .map { |f| File.basename(f, '.svg').match(/\.v(\d+)\z/)&.send(:[], 1).to_i }
        .max || 1
      File.join(dir, "#{base}.v#{existing + 1}.svg")
    end

    def files_to_process
      if @args.filename&.include?(File::SEPARATOR)
        [File.join(@root, @args.filename)]
      else
        base = @args.directory ? File.join(@root, @args.directory) : File.join(@input_dir, '**')
        Dir.glob(File.join(base, @args.filename || '*.svg'))
      end
    end
  end
end