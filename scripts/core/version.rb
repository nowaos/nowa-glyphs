# Everything about the `icon.vN.svg` / `icon-tag.svg` convention in one place.
#
# `fix/*` tasks create versions; `changes/*` promote or discard them. Before,
# the naming regexes and the "refuse to run over a pending version" guard were
# copied across Builder, the batch iterator, and both changes/ scripts.
#
#   Version.for(path).next_path        # icon.v3.svg (next free number)
#   Version.for(path).path_for(n: 2)   # icon.v2.svg
#   Version.for(path).tagged_path("x") # icon-x.svg
#   Version.dest(path, tag:, n:)       # tagged_path / path_for / next_path
#   Version.versioned?(path)           # is this a .vN file?
#   Version.assert_clean!(paths)       # abort if any .vN files are in the set
#   Version.groups_in(target)          # { original => [v2, v3] }
#   Version.list_in(target)            # flat, sorted list of .vN files

module Version
  NUMBER   = /\.v(\d+)\z/          # matches the tail of a basename without .svg
  FILENAME = /\.v\d+\.svg\z/

  module_function

  # True when the basename ends in .vN.svg.
  def versioned?(path)
    File.basename(path).match?(FILENAME)
  end

  # The N from a .vN name, or nil when there is none.
  def number_of(path)
    File.basename(path, '.svg')[NUMBER, 1]&.to_i
  end

  # A Handle for deriving this icon's version and tag paths.
  def for(path)
    Handle.new(path)
  end

  # Destination path for a write: tagged when :tag, an explicit version when :n,
  # otherwise the next free version number.
  def dest(path, tag: nil, n: nil)
    handle = Handle.new(path)
    return handle.tagged_path(tag) if tag
    return handle.path_for(n: n)   if n

    handle.next_path
  end

  # A bare *.vN.svg in the selection means an earlier pass was never promoted or
  # discarded — refuse to stack another version on top of it.
  def assert_clean!(paths)
    pending = paths.select { |p| versioned?(p) }
    return if pending.empty?

    found = pending.map { |p| "v#{number_of(p)}" }.uniq.sort.join(', ')
    abort "Error: #{pending.size} uncommitted versioned file(s) in selection — " \
          "promote or discard them first (rake changes:apply | changes:undo), " \
          "or pass -v N to add another version.\nVersions found: #{found}"
  end

  # Maps each original path to its versions, sorted by version number.
  def groups_in(target)
    glob(target).group_by { |f| original_of(f) }
                .transform_values { |versions| versions.sort_by { |f| number_of(f) } }
  end

  # Flat list of versioned files under target, sorted by dir, base name, number.
  def list_in(target)
    glob(target).sort_by { |f| [File.dirname(f), base_of(f), number_of(f)] }
  end

  # The original .svg path a .vN file belongs to.
  def original_of(versioned_path)
    File.join(File.dirname(versioned_path), "#{base_of(versioned_path)}.svg")
  end

  # Basename without the .svg extension and without any .vN suffix.
  def base_of(path)
    File.basename(path, '.svg').sub(NUMBER, '')
  end

  # Versioned files for a directory (recursive) or for one icon's group,
  # whether the original or one of its versions is passed.
  def glob(target)
    pattern = if File.directory?(target)
      File.join(target, '**', '*.svg')
    else
      File.join(File.dirname(target), "#{base_of(target)}.v*.svg")
    end
    Dir.glob(pattern).select { |f| versioned?(f) }
  end

  class Handle
    # Splits the path into its directory and version-free base name.
    def initialize(path)
      @dir  = File.dirname(path)
      @base = Version.base_of(path)
    end

    # Path using the next free version number (v2 when only the original exists).
    def next_path
      highest = Dir.glob(File.join(@dir, "#{@base}.v*.svg"))
                   .filter_map { |f| Version.number_of(f) }.max || 1
      path_for(n: highest + 1)
    end

    # Path for an explicit version number.
    def path_for(n:)
      File.join(@dir, "#{@base}.v#{n}.svg")
    end

    # Drops a trailing -suffix before adding the tag, so repeated tagging
    # doesn't pile up (icon-old -> icon-new, not icon-old-new).
    def tagged_path(tag)
      File.join(@dir, "#{@base.sub(/-[^.]+\z/, '')}-#{tag}.svg")
    end
  end
end
