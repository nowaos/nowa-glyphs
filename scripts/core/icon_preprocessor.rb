require 'pathname'
require_relative '../lib/svg_tracker'

module IconPreprocessor
  class Args
    VALUED = %w[tag v scope P].freeze

    def initialize(argv = ARGV)
      @options    = {}
      @positional = nil
      parse(argv)
    end

    def positional = @positional
    def fetch(name) = @options[name]
    def includes?(flag) = @options.key?(flag)

    private

    def parse(argv)
      i = 0
      while i < argv.size
        arg = argv[i]
        if arg.start_with?('-')
          name = arg.sub(/\A-+/, '')
          if VALUED.include?(name)
            @options[name] = argv[i + 1]
            i += 2
          else
            @options[name] = true
            i += 1
          end
        else
          abort "Error: unexpected extra argument '#{arg}'" if @positional
          @positional = arg
          i += 1
        end
      end
    end
  end

  class Builder
    attr_reader :tracker, :args

    def initialize(tracker, root, args)
      @tracker   = tracker
      @root      = root
      @args      = args
      @versioned = false
    end

    def template_from(filename)
      path = File.join(@root, 'design', 'templates', 'apps', filename)
      abort "Error: template not found: #{path}" unless File.exist?(path)
      path
    end

    def has_pending_version?
      dir  = File.dirname(@tracker.path)
      base = File.basename(@tracker.path, '.svg').sub(/\.v\d+\z/, '')
      Dir.glob(File.join(dir, "#{base}.v*.svg")).any?
    end

    def create_version(indent: @args.includes?('indent') || @args.includes?('multiline'),
                       multiline: @args.includes?('multiline'))
      path = output_path(@tracker.path)
      @tracker.save(path, indent: indent, multiline: multiline)
      @versioned = true
      path
    end

    def versioned?
      @versioned
    end

    private

    def output_path(path)
      if (tag = @args.fetch('tag'))
        dir  = File.dirname(path)
        base = File.basename(path, '.svg').sub(/\.v\d+\z/, '').sub(/-[^.]+\z/, '')
        File.join(dir, "#{base}-#{tag}.svg")
      elsif (v = @args.fetch('v'))
        dir  = File.dirname(path)
        base = File.basename(path, '.svg').sub(/\.v\d+\z/, '')
        File.join(dir, "#{base}.v#{v}.svg")
      else
        next_version_path(path)
      end
    end

    def next_version_path(path)
      dir  = File.dirname(path)
      base = File.basename(path, '.svg').sub(/\.v\d+\z/, '')
      existing = Dir.glob(File.join(dir, "#{base}.v*.svg"))
        .map { |f| File.basename(f, '.svg').match(/\.v(\d+)\z/)&.[](1).to_i }
        .max || 1
      File.join(dir, "#{base}.v#{existing + 1}.svg")
    end
  end

  class << self
    def each(summary: false, abort_if_versioned: false)
      root      = File.expand_path('../..', __dir__)
      input_dir = File.join(root, 'src', 'apps', 'scalable')
      args      = Args.new

      abort "Error: path argument required (file or directory)" unless args.positional

      target = File.join(root, args.positional)
      files = if File.directory?(target)
        Dir.glob(File.join(target, '**', '*.svg'))
      elsif File.file?(target)
        [target]
      else
        abort "Error: '#{args.positional}' not found"
      end

      if args.fetch('v')
        files = files.reject { |f| File.basename(f).match?(/\.v\d+\.svg\z/) }
      elsif abort_if_versioned && !args.fetch('tag')
        versioned = files.select { |f| File.basename(f).match?(/\.v\d+\.svg\z/) }
        unless versioned.empty?
          abort "Error: uncommitted versioned files in selection — commit or remove them first:\n" +
                versioned.map { |f| "  #{Pathname.new(f).relative_path_from(root)}" }.join("\n")
        end
      end

      count = 0
      files.each do |file_path|
        tracker = SvgTracker.new(file_path)
        builder = Builder.new(tracker, root, args)
        yield builder, tracker
        count += 1 if builder.versioned?
      end

      puts "Done. #{count} file(s) processed." if summary
    end
  end
end
