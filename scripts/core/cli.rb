# Small opt-in argv parser. Each task declares the flags it accepts:
#
#   cli = Cli.parse(ARGV, flags: %i[dry_run multiline], values: %i[scope v])
#   cli.path            # first positional (nil if none)
#   cli.paths           # every positional
#   cli.dry_run?        # declared boolean flag
#   cli.value(:scope)   # flag that consumes the next token, or nil
#
# Leading dashes are stripped and inner dashes become underscores, so `--dry-run`
# and `-dry-run` both read as `dry_run`. A lone `--` (Rake passes it through) is
# ignored. Undeclared `-x` flags still parse as booleans.

class Cli
  # ANSI color codes for task output.
  RED   = "\e[31m"
  GREEN = "\e[32m"
  DIM   = "\e[2m"
  RESET = "\e[0m"

  # Every positional argument, in the order given.
  attr_reader :paths

  # Parses argv into declared boolean flags, value flags, and positionals.
  def initialize(argv, flags, values)
    @flags  = flags.map { |f| key(f) }
    @values = values.map { |v| key(v) }
    @opts   = {}
    @paths  = []
    scan(argv.reject { |a| a == '--' })
  end

  # Entry point: declares which names are boolean flags and which consume a value.
  def self.parse(argv = ARGV, flags: [], values: [])
    new(argv, flags, values)
  end

  # First positional argument, or nil.
  def path = @paths.first

  # Value that followed a `values:` flag, or nil if it was not passed.
  def value(name) = @opts[key(name)]

  # Whether a boolean flag was passed.
  def flag?(name) = @opts.fetch(key(name), false) == true

  private

  # Lets `cli.foo?` be answered by method_missing below.
  def respond_to_missing?(name, include_private = false)
    name.to_s.end_with?('?') || super
  end

  # Routes any `name?` call to the matching boolean flag.
  def method_missing(name, *args)
    return super unless args.empty? && name.to_s.end_with?('?')
    flag?(name.to_s.chomp('?'))
  end

  # Normalizes a flag name ("--dry-run") to its lookup symbol (:dry_run).
  def key(name) = name.to_s.sub(/\A-+/, '').tr('-', '_').to_sym

  # Walks argv, sorting tokens into positionals, value flags, and boolean flags.
  def scan(args)
    i = 0
    while i < args.size
      arg = args[i]
      unless arg.start_with?('-')
        @paths << arg
        i += 1
        next
      end

      name = key(arg)
      if @values.include?(name)
        @opts[name] = args[i + 1]
        i += 2
      else
        @opts[name] = true
        i += 1
      end
    end
  end
end
