require 'fileutils'
require 'ostruct'
require_relative 'svg_tracker'

module IconPreprocessor
  class << self
    attr_reader :args

    def setup(argv = ARGV, base_dir: nil)
      @base_dir = base_dir || File.join(__dir__, '..', '..', 'src', 'apps')
      @input_dir = File.join(@base_dir, 'scalable')
      
      ds_square = File.join(@base_dir, 'templates', 'ds.svg')
      ds_round = File.join(@base_dir, 'templates', 'ds-round.svg')
      @ds = OpenStruct.new(ds_square: ds_square, ds_round: ds_round)

      abort "Error: template not found: #{ds_square}" unless File.exist?(ds_square)
      abort "Error: template not found: #{ds_round}" unless File.exist?(ds_round)

      filename = nil
      argv.each_with_index do |arg, i|
        filename = argv[i + 1] if arg == '-f'
      end

      @args = OpenStruct.new(
        filename: filename,
        new: argv.include?('--new')
      )
    end

    def update(&block)
      setup unless @args
      count = 0
      
      files_to_process.each do |file_path|
        tracker = SvgTracker.new(file_path)
        
        yield tracker, @ds
        
        output_path = @args.new ? file_path.sub(/\.svg$/, '.new.svg') : file_path

        tracker.save(output_path)
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

    def files_to_process
      if @args.filename
        [File.join(@input_dir, @args.filename)]
      else
        Dir.glob(File.join(@input_dir, '*.svg'))
      end
    end
  end
end