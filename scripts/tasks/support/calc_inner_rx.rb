#!/usr/bin/env ruby
# Calculates the rx for a nested rounded rectangle that visually follows the outer shape.
#
# Based on outer canvas: 55×55, rx=10.
# Formula: rx_inner = rx_outer - (outer_size - inner_size) / 2
#
# Usage:
#   rake support:calc_inner_rx -- 48

OUTER_SIZE = 55
OUTER_RX   = 10

ARGV.delete('--')
abort "Usage: rake support:calc_inner_rx -- <inner_size>" if ARGV.empty?

inner = ARGV[0].to_f
padding = (OUTER_SIZE - inner) / 2.0
rx = OUTER_RX - padding

puts "inner: #{inner}×#{inner}  →  rx: #{rx.round(4)}"
