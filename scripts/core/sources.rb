require_relative 'paths'
require_relative 'version'

# Turns a task's path argument into the list of SVGs to work on, with the
# filters each task actually wants stacked on explicitly:
#
#   Sources.resolve(cli.path, fallback: Paths::SRC)  # file | directory (**/*.svg) | absolute; fallback used when arg is nil
#          .reject_symlinks!
#          .reject_versions!                          # drop *.vN.svg
#          .each { |path| ... }
#
# A relative argument resolves against the repo root (not against the fallback),
# so `sandbox` and `test/tmp/x.svg` work regardless of `fallback:`.

class Sources
  include Enumerable

  # Resolves arg (a file, a directory, or nil) to the sorted SVG list;
  # uses `fallback` when arg is nil, and aborts when nothing matches.
  def initialize(arg, fallback: nil)
    target = arg ? Paths.absolute(arg) : (fallback or abort('Error: path argument required (file or directory)'))

    @files =
      if File.directory?(target)
        Dir.glob(File.join(target, '**', '*.svg')).sort
      elsif File.file?(target)
        [target]
      else
        abort "Error: '#{arg || target}' not found"
      end
  end

  # Entry point: builds a resolved Sources ready to filter and iterate.
  def self.resolve(arg, fallback: nil) = new(arg, fallback: fallback)

  # Drops symlinked files from the set.
  def reject_symlinks!
    @files = @files.reject { |f| File.symlink?(f) }
    self
  end

  # Drops *.vN.svg version files from the set.
  def reject_versions!
    @files = @files.reject { |f| Version.versioned?(f) }
    self
  end

  # Yields each resolved path.
  def each(&block) = @files.each(&block)

  # Copy of the resolved path list.
  def to_a  = @files.dup
  # How many paths resolved.
  def size  = @files.size
  # True when nothing resolved.
  def empty? = @files.empty?
end
