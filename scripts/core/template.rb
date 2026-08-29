require_relative 'paths'

# Canonical icon fragments under design/templates/apps/ (e.g. the drop-shadow
# group merged in by fix:update_shadows).

module Template
  module_function

  # Absolute path to a fragment under design/templates/apps/; aborts if missing.
  def apps(filename)
    path = Paths::TEMPLATES / filename
    abort "Error: template not found: #{path}" unless File.exist?(path)

    path
  end
end
