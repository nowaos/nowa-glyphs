#!/usr/bin/env ruby
# Generates design/assets/chroma-analysis.html
# Shows three chroma series by hue:
#   1. sRGB gamut max (upper bound, at L=0.65)
#   2. Reversal T4 anchors (reference we calibrated from)
#   3. Our palette max C per chromatic family

require 'yaml'
require 'json'
require_relative '../lib/palette'

ROOT = File.expand_path('../..', __dir__)

REVERSAL_T4 = {
  'red'    => '#f83f3f',
  'yellow' => '#ffdc32',
  'green'  => '#7dcd32',
  'blue'   => '#329bff',
  'purple' => '#a53cff'
}

GRAY_FAMILIES = %w[gray-light gray-dark].freeze

def oklch_to_linear_rgb(l, c, h)
  h_rad = h * Math::PI / 180
  a = c * Math.cos(h_rad)
  b = c * Math.sin(h_rad)

  lm = (l + 0.3963377774 * a + 0.2158037573 * b)**3
  mm = (l - 0.1055613458 * a - 0.0638541728 * b)**3
  sm = (l - 0.0894841775 * a - 1.2914855480 * b)**3

  [
     4.0767416621 * lm - 3.3077115913 * mm + 0.2309699292 * sm,
    -1.2684380046 * lm + 2.6097574011 * mm - 0.3413193965 * sm,
    -0.0041960863 * lm - 0.7034186147 * mm + 1.7076147010 * sm
  ]
end

def in_srgb?(l, c, h)
  oklch_to_linear_rgb(l, c, h).all? { |v| v >= -0.0005 && v <= 1.0005 }
end

def max_srgb_chroma(hue, lightness)
  lo, hi = 0.0, 0.45
  25.times do
    mid = (lo + hi) / 2
    in_srgb?(lightness, mid, hue) ? lo = mid : hi = mid
  end
  lo.round(4)
end

# --- Gamut boundary at representative lightness values ---
puts "Computing sRGB gamut boundary..."
LIGHTNESSES = { '0.55' => 0.55, '0.65' => 0.65, '0.75' => 0.75 }
gamut = {}
LIGHTNESSES.each do |label, lval|
  gamut[label] = (0..360).step(2).map { |h| [h, max_srgb_chroma(h, lval)] }
  print '.'
end
puts

# --- Palette families ---
data = YAML.load_file(File.join(ROOT, 'design/assets/palette.yaml'))

def circular_mean(hues)
  sin_sum = hues.sum { |h| Math.sin(h * Math::PI / 180) }
  cos_sum = hues.sum { |h| Math.cos(h * Math::PI / 180) }
  (Math.atan2(sin_sum, cos_sum) * 180 / Math::PI) % 360
end

palette_families = data['colors']
  .reject { |name, _| GRAY_FAMILIES.include?(name) }
  .map do |name, tones|
    lchs = tones.map { |hex| Palette.hex_to_oklch(hex.downcase) }.compact
    next nil if lchs.empty?

    hues  = lchs.map { |_, _, h| h }
    max_c = lchs.map { |_, c, _| c }.max
    tone400 = tones[3]&.downcase

    { name: name, hue: circular_mean(hues).round(1), maxC: max_c.round(4), color: tone400 }
  end
  .compact
  .sort_by { |f| f[:hue] }

# --- Reversal T4 ---
reversal = REVERSAL_T4.map do |name, hex|
  lch = Palette.hex_to_oklch(hex)
  next nil unless lch
  { name: name, hue: lch[2].round(1), chroma: lch[1].round(4), hex: hex }
end.compact

# --- Purple reduction previews ---
purple_family = palette_families.find { |f| f[:name] == 'purple' }
purple_previews = [0.90, 0.85].map do |mult|
  { label: "×#{mult}", hue: purple_family[:hue], maxC: (purple_family[:maxC] * mult).round(4) }
end

# --- Embed in HTML ---
html = <<~HTML
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>Chroma Analysis — Nowa Glyphs v3</title>
    <style>
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body { background: #1c1c1e; color: #f2f2f7; font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 40px; }
      h1 { font-size: 18px; font-weight: 500; margin-bottom: 6px; }
      .subtitle { font-size: 13px; color: #8e8e93; margin-bottom: 32px; }
      canvas { display: block; border-radius: 12px; background: #2c2c2e; }
      .legend { display: flex; gap: 28px; margin-top: 20px; font-size: 13px; color: #c7c7cc; }
      .legend-item { display: flex; align-items: center; gap: 8px; }
      .swatch-line { width: 28px; height: 3px; border-radius: 2px; }
      .swatch-dot { width: 10px; height: 10px; border-radius: 50%; }
    </style>
  </head>
  <body>
    <h1>Chroma by Hue — Nowa Glyphs v3</h1>
    <p class="subtitle">sRGB gamut boundary vs Reversal T4 reference vs our palette max chroma per family</p>
    <canvas id="chart" width="940" height="500"></canvas>
    <div class="legend">
      <div class="legend-item">
        <div class="swatch-line" style="background:rgba(255,255,255,0.25);border:1px dashed rgba(255,255,255,0.4)"></div>
        <span>sRGB gamut max (L=0.55 / 0.65 / 0.75)</span>
      </div>
      <div class="legend-item">
        <div class="swatch-dot" style="background:#ff9f43;border:2px solid #fff"></div>
        <span>Reversal T4 anchors</span>
      </div>
      <div class="legend-item">
        <div class="swatch-line" style="background:#67bbf6"></div>
        <span>Nowa Glyphs v3 palette max C</span>
      </div>
    </div>
    <script>
      const GAMUT    = #{gamut.to_json};
      const PALETTE  = #{palette_families.to_json};
      const REVERSAL = #{reversal.to_json};
      const PURPLE_PREVIEWS = #{purple_previews.to_json};

      const W = 940, H = 500;
      const PAD = { top: 36, right: 30, bottom: 56, left: 58 };
      const CW = W - PAD.left - PAD.right;
      const CH = H - PAD.top - PAD.bottom;
      const MAX_C = 0.40;

      const canvas = document.getElementById('chart');
      const ctx = canvas.getContext('2d');

      function hx(h) { return PAD.left + (h / 360) * CW; }
      function cy(c) { return PAD.top  + CH - (c / MAX_C) * CH; }

      // Hue background
      for (let h = 0; h < 360; h++) {
        const x = hx(h);
        const grad = ctx.createLinearGradient(0, PAD.top, 0, PAD.top + CH);
        grad.addColorStop(0,   `oklch(0.68 0.18 ${h} / 0.10)`);
        grad.addColorStop(1,   `oklch(0.68 0.18 ${h} / 0.00)`);
        ctx.fillStyle = grad;
        ctx.fillRect(x, PAD.top, CW / 360 + 1, CH);
      }

      // Grid — chroma
      ctx.setLineDash([3, 5]);
      ctx.lineWidth = 1;
      ctx.font = '11px -apple-system, sans-serif';
      ctx.textAlign = 'right';
      for (let c = 0; c <= MAX_C + 0.001; c += 0.05) {
        ctx.strokeStyle = c === 0 ? '#636366' : '#3a3a3c';
        ctx.beginPath(); ctx.moveTo(PAD.left, cy(c)); ctx.lineTo(PAD.left + CW, cy(c)); ctx.stroke();
        if (c > 0) {
          ctx.fillStyle = '#636366';
          ctx.fillText(c.toFixed(2), PAD.left - 6, cy(c) + 4);
        }
      }

      // Grid — hue
      ctx.textAlign = 'center';
      for (let h = 0; h <= 360; h += 30) {
        ctx.strokeStyle = '#3a3a3c';
        ctx.beginPath(); ctx.moveTo(hx(h), PAD.top); ctx.lineTo(hx(h), PAD.top + CH); ctx.stroke();
        ctx.fillStyle = '#636366';
        ctx.fillText(h + '°', hx(h), PAD.top + CH + 18);
      }
      ctx.setLineDash([]);

      // Axes
      ctx.strokeStyle = '#48484a';
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(PAD.left, PAD.top);
      ctx.lineTo(PAD.left, PAD.top + CH);
      ctx.lineTo(PAD.left + CW, PAD.top + CH);
      ctx.stroke();

      // Axis labels
      ctx.fillStyle = '#8e8e93';
      ctx.font = '12px -apple-system, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('Hue (°)', PAD.left + CW / 2, H - 10);
      ctx.save();
      ctx.translate(14, PAD.top + CH / 2);
      ctx.rotate(-Math.PI / 2);
      ctx.fillText('Chroma (C)', 0, 0);
      ctx.restore();

      // sRGB gamut bands
      const lLabels = Object.keys(GAMUT);
      const lColors = ['rgba(255,255,255,0.10)', 'rgba(255,255,255,0.18)', 'rgba(255,255,255,0.10)'];
      lLabels.forEach((lkey, i) => {
        const pts = GAMUT[lkey];
        ctx.beginPath();
        pts.forEach(([h, c], j) => {
          j === 0 ? ctx.moveTo(hx(h), cy(c)) : ctx.lineTo(hx(h), cy(c));
        });
        ctx.strokeStyle = lColors[i];
        ctx.lineWidth = i === 1 ? 2 : 1;
        ctx.setLineDash(i === 1 ? [] : [4, 4]);
        ctx.stroke();
        ctx.setLineDash([]);
      });

      // Palette line
      const sorted = [...PALETTE].sort((a, b) => a.hue - b.hue);
      ctx.beginPath();
      sorted.forEach((f, i) => {
        i === 0 ? ctx.moveTo(hx(f.hue), cy(f.maxC)) : ctx.lineTo(hx(f.hue), cy(f.maxC));
      });
      ctx.strokeStyle = '#67bbf6';
      ctx.lineWidth = 2.5;
      ctx.stroke();

      // Palette dots + labels
      sorted.forEach(f => {
        const x = hx(f.hue), y = cy(f.maxC);
        ctx.beginPath();
        ctx.arc(x, y, 5, 0, Math.PI * 2);
        ctx.fillStyle = f.color || '#67bbf6';
        ctx.fill();
        ctx.strokeStyle = 'rgba(255,255,255,0.6)';
        ctx.lineWidth = 1;
        ctx.stroke();

        ctx.fillStyle = '#aeaeb2';
        ctx.font = '9px -apple-system, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(f.name, x, y - 9);
      });

      // Reversal T4 dots
      REVERSAL.forEach(r => {
        const x = hx(r.hue), y = cy(r.chroma);
        ctx.beginPath();
        ctx.arc(x, y, 8, 0, Math.PI * 2);
        ctx.fillStyle = r.hex;
        ctx.fill();
        ctx.strokeStyle = '#ff9f43';
        ctx.lineWidth = 2;
        ctx.stroke();

        ctx.fillStyle = '#ff9f43';
        ctx.font = 'bold 10px -apple-system, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(r.name, x, y + 20);
      });

      // Purple reduction previews
      const previewColors = ['#c084fc', '#a855f7'];
      PURPLE_PREVIEWS.forEach((p, i) => {
        const x = hx(p.hue), y = cy(p.maxC);
        // Dashed horizontal line from current purple dot
        const purpleDot = PALETTE.find(f => f.name === 'purple');
        ctx.beginPath();
        ctx.setLineDash([4, 3]);
        ctx.strokeStyle = previewColors[i];
        ctx.lineWidth = 1.5;
        ctx.moveTo(hx(purpleDot.hue), cy(purpleDot.maxC));
        ctx.lineTo(x, y);
        ctx.stroke();
        ctx.setLineDash([]);

        ctx.beginPath();
        ctx.arc(x, y, 5, 0, Math.PI * 2);
        ctx.fillStyle = previewColors[i];
        ctx.fill();
        ctx.strokeStyle = 'rgba(255,255,255,0.5)';
        ctx.lineWidth = 1;
        ctx.stroke();

        ctx.fillStyle = previewColors[i];
        ctx.font = '10px -apple-system, sans-serif';
        ctx.textAlign = 'left';
        ctx.fillText(p.label, x + 8, y + 4);
      });
    </script>
  </body>
  </html>
HTML

output = File.join(ROOT, 'design/assets/chroma-analysis.html')
File.write(output, html)
puts "Generated: #{output}"
