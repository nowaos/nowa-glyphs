#!/usr/bin/env ruby
# Palette v3 — current palette
#
# Change from v2: BUMP reduced from 1.0 → 0.90 (global chroma multiplier in OKLCH).
# v2 felt slightly too vivid for an icon theme; lowering BUMP 10% gives a softer
# feel while keeping hue identity. Approved after side-by-side comparison with v2
# and the GNOME HIG palette — v3 sits close to GNOME on orange/red, slightly
# more vivid on blue/purple.
#
# Usage: ruby scripts/v3/gen_palette.rb

require 'yaml'

# ── sRGB ↔ linear ────────────────────────────────────────────────────────────

def srgb_to_linear(c)
  c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
end

def linear_to_srgb(c)
  c = c.clamp(0.0, 1.0)
  c <= 0.0031308 ? 12.92 * c : 1.055 * (c ** (1.0 / 2.4)) - 0.055
end

# ── sRGB hex ↔ OKLCH ─────────────────────────────────────────────────────────
# Matrices from Björn Ottosson's reference implementation (bottosson.github.io)

M1 = [
  [0.4122214708, 0.5363325363, 0.0514459929],
  [0.2119034982, 0.6806995451, 0.1073969566],
  [0.0883024619, 0.2817188376, 0.6299787005],
]

M2 = [
  [ 0.2104542553,  0.7936177850, -0.0040720468],
  [ 1.9779984951, -2.4285922050,  0.4505937099],
  [ 0.0259040371,  0.7827717662, -0.8086757660],
]

M1_INV = [
  [ 4.0767416621, -3.3077115913,  0.2309699292],
  [-1.2684380046,  2.6097574011, -0.3413193965],
  [-0.0041960863, -0.7034186147,  1.7076147010],
]

M2_INV = [
  [1.0,  0.3963377774,  0.2158037573],
  [1.0, -0.1055613458, -0.0638541728],
  [1.0, -0.0894841775, -1.2914855480],
]

def mat3(m, v)
  m.map { |row| row.zip(v).sum { |a, b| a * b } }
end

def hex_to_oklch(hex)
  h = hex.delete('#')
  r, g, b = [h[0,2], h[2,2], h[4,2]].map { |v| srgb_to_linear(v.to_i(16) / 255.0) }

  lms  = mat3(M1, [r, g, b])
  lms_ = lms.map { |v| Math.cbrt(v) }
  lab  = mat3(M2, lms_)

  l, a, b2 = lab
  c = Math.sqrt(a**2 + b2**2)
  h_deg = Math.atan2(b2, a) * 180.0 / Math::PI
  h_deg += 360 if h_deg < 0

  [l, c, h_deg]
end

def oklch_to_hex(l, c, h)
  h_rad = h * Math::PI / 180.0
  a, b  = c * Math.cos(h_rad), c * Math.sin(h_rad)

  lms_ = mat3(M2_INV, [l, a, b])
  lms  = lms_.map { |v| v**3 }
  rgb  = mat3(M1_INV, lms).map { |v| linear_to_srgb(v.clamp(0, 1)) }

  "#%02x%02x%02x" % rgb.map { |v| (v.clamp(0, 1) * 255).round }
end

def in_gamut?(l, c, h)
  h_rad = h * Math::PI / 180.0
  a, b  = c * Math.cos(h_rad), c * Math.sin(h_rad)
  lms_  = mat3(M2_INV, [l, a, b])
  lms   = lms_.map { |v| v**3 }
  rgb   = mat3(M1_INV, lms)
  rgb.all? { |v| v >= -0.001 && v <= 1.001 }
end

def max_chroma(l, h, steps: 28)
  lo, hi = 0.0, 0.45
  steps.times { mid = (lo + hi) / 2.0; in_gamut?(l, mid, h) ? lo = mid : hi = mid }
  lo
end

# ── Reference colors (Reversal dominant colors, used as tone-4 anchors) ───────

REVERSAL_T4 = {
  red:    '#f83f3f',  # 21 occurrences
  yellow: '#ffdc32',  #  8 occurrences
  green:  '#7dcd32',  #  9 occurrences
  blue:   '#329bff',  # 27 occurrences (sky-ish, hue ~215°)
  purple: '#a53cff',  #  5 occurrences
}

reversal_lch = REVERSAL_T4.transform_values { |hex| hex_to_oklch(hex) }

$stderr.puts "=== Reversal tone 4 → OKLCH ==="
reversal_lch.each do |name, (l, c, h)|
  $stderr.puts "  #{name.to_s.ljust(8)} L=#{l.round(3)}  C=#{c.round(3)}  H=#{h.round(1)}°"
end

STEP  = 0.09
L_MAX = 0.93
L_MIN = 0.26

# ── Hue grid: 15 families equally spaced at 24° starting from cherry = 1° ────
# cherry(1°) red(25°) orange(49°) amber(73°) yellow(97°) lime(121°) green(145°)
# mint(169°) cyan(193°) turquoise(217°) sky(241°) blue(265°) indigo(289°) purple(313°) pink(337°)

GRID_FAMILIES = %i[cherry red orange amber yellow lime green mint cyan turquoise sky blue indigo purple pink]

hues = {}
GRID_FAMILIES.each_with_index { |name, i| hues[name] = (1.0 + i * 24.0) % 360.0 }
hues[:brown] = hues[:orange]

# L and C: Reversal primaries anchor their grid positions; all others interpolate
anchors_raw = {
  hues[:red]    => { l: reversal_lch[:red][0],    c: reversal_lch[:red][1]    },
  hues[:yellow] => { l: reversal_lch[:yellow][0], c: reversal_lch[:yellow][1] },
  hues[:green]  => { l: reversal_lch[:green][0],  c: reversal_lch[:green][1]  },
  hues[:sky]    => { l: reversal_lch[:blue][0],   c: reversal_lch[:blue][1]   },
  hues[:indigo] => { l: reversal_lch[:purple][0], c: reversal_lch[:purple][1] },
}
sorted_anchors = anchors_raw.sort_by { |h, _| h }

def interp_wheel(sorted_anchors, target_h, key)
  n        = sorted_anchors.length
  idx_next = sorted_anchors.find_index { |h, _| h > target_h } || 0
  idx_prev = (idx_next - 1 + n) % n
  h_prev, dp = sorted_anchors[idx_prev]
  h_next, dn = sorted_anchors[idx_next]
  span = ((h_next - h_prev) + 360) % 360
  dist = ((target_h - h_prev) + 360) % 360
  t    = span > 0 ? dist.to_f / span : 0.0
  dp[key] * (1 - t) + dn[key] * t
end

base_ls = {}
GRID_FAMILIES.each { |name| base_ls[name] = interp_wheel(sorted_anchors, hues[name], :l) }
base_ls[:brown] = base_ls[:orange] - 2 * STEP

avg_c = anchors_raw.values.map { |v| v[:c] }.sum / anchors_raw.size
BUMP  = 0.90

target_c = {}
GRID_FAMILIES.each { |name| target_c[name] = interp_wheel(sorted_anchors, hues[name], :c) * BUMP }
%i[cherry orange amber lime pink purple].each { |name| target_c[name] = avg_c * BUMP * 1.05 }
target_c[:brown] = target_c[:orange] * 0.60

$stderr.puts "\n=== Grid hues & base L ==="
GRID_FAMILIES.each do |n|
  $stderr.puts "  #{n.to_s.ljust(8)} H=#{hues[n].round(1)}°  base_L=#{base_ls[n].round(3)}"
end

# ── Lightness scale anchored per family ──────────────────────────────────────
# tone 400 = Reversal tone-4 L for that family (its natural rich point)
# tones above: equal steps up, but when limited headroom exists the gap is split evenly
# tones below: equal steps down, floor 0.26

def l_scale(base_l)
  above_3 = base_l + 3 * STEP

  if above_3 > L_MAX
    # Compress the above range into available headroom, split into 3 equal parts
    gap = L_MAX - base_l
    a1 = base_l + gap / 3.0
    a2 = base_l + gap * 2.0 / 3.0
    a3 = L_MAX
  else
    a1 = base_l + STEP
    a2 = base_l + 2 * STEP
    a3 = above_3
  end

  {
    100 => a3,
    200 => a2,
    300 => a1,
    400 => base_l,
    500 => [base_l - STEP,       L_MIN].max,
    600 => [base_l - 2 * STEP,   L_MIN].max,
    700 => [base_l - 3 * STEP,   L_MIN].max,
  }
end

# ── Generate all families ─────────────────────────────────────────────────────

ORDER = %i[red orange amber yellow lime green mint cyan turquoise sky blue indigo purple pink cherry brown]

USAGE = {
  red:    'Alerts · recording · errors',
  orange: 'Audio & video · media',
  amber:  'Highlights · warmth · harvest',
  yellow: 'Games · highlights · favorites',
  lime:   'Nature · agriculture · growth',
  green:  'Education · productivity · success',
  mint:   'Health · nature · freshness',
  cyan:   'Science · data · system',
  turquoise: 'Cloud · air · open',
  sky:       'Sky · social · network',
  blue:      'Internet · communication · network',
  indigo: 'Development · system · terminal',
  purple: 'Graphics · design · creativity',
  pink:   'Multimedia · entertainment · social',
  cherry: 'Danger · critical · warnings',
  brown:  'Files · office · paper · cardboard',
}

palette = { 'colors' => {} }

# Chroma ramp: light tones are pastel, full chroma at 400-500, slight taper at 700
CHROMA_RAMP = { 100 => 0.25, 200 => 0.50, 300 => 0.75, 400 => 1.0, 500 => 1.0, 600 => 0.95, 700 => 0.88 }

ORDER.each do |name|
  h     = hues[name]
  tc    = target_c[name]
  scale = l_scale(base_ls[name])

  tones = scale.each_with_object({}) do |(tone, l), acc|
    mc = max_chroma(l, h)
    c  = [tc * CHROMA_RAMP[tone], mc * 0.97].min
    acc[tone] = oklch_to_hex(l, c, h)
  end

  palette['colors'][name.to_s] = {
    'name'  => name.to_s.capitalize,
    'usage' => USAGE[name],
    'tones' => tones.transform_keys(&:to_s),
  }
end

# ── Write output ──────────────────────────────────────────────────────────────

NEUTRAL = [
  { id: 'gray-light', name: 'Gray Light', usage: 'Backgrounds · surfaces · disabled',
    tones: { 100 => '#f2f2f7', 200 => '#e5e5ea', 300 => '#d1d1d6', 400 => '#c7c7cc',
             500 => '#aeaeb2', 600 => '#8e8e93', 700 => '#636366' } },
  { id: 'gray-dark',  name: 'Gray Dark',  usage: 'Text · icons · dark surfaces',
    tones: { 100 => '#636366', 200 => '#48484a', 300 => '#3a3a3c', 400 => '#2c2c2e',
             500 => '#1c1c1e', 600 => '#111112', 700 => '#080808' } },
]

ICON_USAGE = {
  'applications-internet'    => 'sky',
  'applications-development' => 'blue',
  'applications-graphics'    => 'indigo',
  'applications-office'      => 'brown',
  'applications-audiovideo'  => 'orange',
  'applications-accessories' => 'cyan',
  'applications-all'         => 'gray-light',
  'applications-featured'    => 'yellow',
  'applications-settings'    => 'gray-dark',
  'applications-games'       => 'yellow',
  'applications-education'   => 'green',
  'applications-science'     => 'cyan',
  'applications-system'      => 'blue',
  'applications-utilities'   => 'sky',
}

if ARGV.include?('--stdout')
  palette['colors'].each do |name, data|
    $stdout.puts "#{name}:"
    data['tones'].each { |t, hex| $stdout.puts "  #{t}: \"#{hex}\"" }
  end
else
  def js_tones(tones)
    tones.map { |t, hex| "#{t}:\"#{hex}\"" }.join(',')
  end

  chromatic_js = palette['colors'].map do |name, data|
    %Q(  { id:"#{name}", name:"#{data['name']}", usage:"#{data['usage']}", tones:{#{js_tones(data['tones'])}} })
  end.join(",\n")

  neutral_js = NEUTRAL.map do |c|
    %Q(  { id:"#{c[:id]}", name:"#{c[:name]}", usage:"#{c[:usage]}", tones:{#{js_tones(c[:tones])}} })
  end.join(",\n")

  icon_usage_js = ICON_USAGE.map do |icon, color|
    %Q(  { icon:"#{icon}", color:"#{color}" })
  end.join(",\n")

  js = <<~JS
    // Generated by design/v3/gen_palette.rb — do not edit manually
    ;(function() {
      const CHROMATIC = [
    #{chromatic_js}
      ];
      const NEUTRAL = [
    #{neutral_js}
      ];
      const ICON_USAGE = [
    #{icon_usage_js}
      ];
      window.PALETTES = window.PALETTES || {};
      window.PALETTES.v3 = { CHROMATIC, NEUTRAL, ICON_USAGE };
    })();
  JS

  assets = File.join(__dir__, '../../design/assets')
  File.write(File.join(assets, 'palette-data.js'), js)
  $stderr.puts "\n✓ Wrote design/assets/palette-data.js"

  yaml_colors = {}
  palette['colors'].each { |name, data| yaml_colors[name] = data['tones'].values }
  NEUTRAL.each { |c| yaml_colors[c[:id]] = c[:tones].values }
  yaml = { 'scale' => [100, 200, 300, 400, 500, 600, 700], 'default_tone' => 400, 'colors' => yaml_colors }
  File.write(File.join(assets, 'palette.yaml'), yaml.to_yaml)
  $stderr.puts "✓ Wrote design/assets/palette.yaml"
end

# ── Print summary ─────────────────────────────────────────────────────────────

$stderr.puts "\n=== Generated tones ==="
ORDER.each do |name|
  tones = palette['colors'][name.to_s]['tones']
  $stderr.puts "  #{name.to_s.ljust(8)} #{tones.values.join('  ')}"
end
