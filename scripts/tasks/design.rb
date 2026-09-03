#!/usr/bin/env ruby
# Opens the design system HTML in the default browser (xdg-open).
#
# Usage:
#   rake design

FILE = File.expand_path('../../design/v4/design-system.html', __dir__)

abort "Error: not found: #{FILE}" unless File.exist?(FILE)

system('xdg-open', FILE) or abort 'Error: xdg-open failed (is it installed?)'
