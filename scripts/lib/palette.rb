require 'yaml'

class Palette
  SKIP = %w[#ffffff #000000].to_set

  def self.load(yaml_path)
    data = YAML.load_file(yaml_path)
    colors = {}
    data['colors'].each_value do |tones|
      tones.each do |hex|
        hex = hex.downcase
        lab = hex_to_oklab(hex)
        colors[hex] = lab if lab && !colors.key?(hex)
      end
    end
    new(colors)
  end

  def map_to_closest(hexes)
    hexes.each_with_object({}) do |hex, mapping|
      mapping[hex] = closest(hex)
    end
  end

  private

  def initialize(colors)
    @colors = colors
  end

  def closest(hex)
    hex = hex.downcase
    return hex if SKIP.include?(hex)

    lab = self.class.hex_to_oklab(hex)
    return hex unless lab

    best_hex, best_dist = hex, Float::INFINITY
    @colors.each do |phex, plab|
      d = lab_dist(lab, plab)
      if d < best_dist
        best_dist = d
        best_hex = phex
      end
    end
    best_hex
  end

  def lab_dist(a, b)
    Math.sqrt((a[0] - b[0])**2 + (a[1] - b[1])**2 + (a[2] - b[2])**2)
  end

  def self.hex_to_oklab(hex)
    h = hex.delete_prefix('#').downcase
    return nil unless h.length == 6 && h.match?(/\A[0-9a-f]{6}\z/)

    r = linearize(h[0, 2].to_i(16) / 255.0)
    g = linearize(h[2, 2].to_i(16) / 255.0)
    b = linearize(h[4, 2].to_i(16) / 255.0)

    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    l, m, s = [l, m, s].map { |x| x < 0 ? -((-x)**(1.0 / 3)) : x**(1.0 / 3) }

    [
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    ]
  end

  def self.linearize(c)
    c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
  end
end
