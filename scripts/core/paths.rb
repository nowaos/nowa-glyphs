# Repo-relative paths every task needs, resolved once instead of
# `File.expand_path('../../..', __dir__)` copied into each script.
#
# ROOT/SRC/TEMPLATES are Pathnames, so callers compose with `ROOT / 'some/dir'`.
# `absolute` resolves a task argument (already-absolute args pass through);
# `relative` strips the root prefix for display.

require 'pathname'

module Paths
  ROOT      = Pathname(File.expand_path('../..', __dir__))
  SRC       = ROOT / 'src/apps/scalable'
  TEMPLATES = ROOT / 'design/templates/apps'

  module_function

  # Resolves arg against the repo root; an absolute arg is returned unchanged.
  def absolute(arg) = ROOT / arg

  # Path relative to the repo root, for display.
  def relative(path) = Pathname(path).relative_path_from(ROOT)
end
