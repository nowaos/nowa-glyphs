require 'yaml'

class Palette
  SKIP = %w[#ffffff #000000].to_set
  ACHROMATIC_C = 0.04  # OKLCH chroma below this → treat as gray
  GRAY_FAMILIES  = %w[gray-light gray-dark].freeze
  MUTED_FAMILIES = %w[brown].freeze  # share a hue with another family; resolved by chroma proximity

  def self.load(yaml_path)
    data = YAML.load_file(yaml_path)
    families = {}
    data['colors'].each do |name, tones|
      families[name] = tones.map { |hex|
        hex = hex.downcase
        lch = hex_to_oklch(hex)
        { hex: hex, lch: lch } if lch
      }.compact
    end
    new(families)
  end

  def map_to_closest(hexes)
    hexes.each_with_object({}) do |hex, mapping|
      mapping[hex] = closest(hex)
    end
  end

  private

  def initialize(families)
    @families = families
    @chromatic = families.reject { |n, _| GRAY_FAMILIES.include?(n) || MUTED_FAMILIES.include?(n) }
    @grays     = families.select { |n, _| GRAY_FAMILIES.include?(n) }
    @muted     = families.select { |n, _| MUTED_FAMILIES.include?(n) }

    @family_hues = @chromatic.transform_values do |tones|
      hues = tones.map { |t| t[:lch][2] }.compact
      hues.empty? ? nil : circular_mean(hues)
    end

    # Map each muted family to its chromatic counterpart for tiebreaking
    @muted_peers = { 'brown' => 'orange' }
  end

  def closest(hex)
    hex = hex.downcase
    return hex if SKIP.include?(hex)

    lch = self.class.hex_to_oklch(hex)
    return hex unless lch

    l, c, h = lch

    if c < ACHROMATIC_C
      @grays.values.flatten.min_by { |t| (t[:lch][0] - l).abs }[:hex]
    else
      family = @family_hues.min_by { |_, fh| fh ? hue_dist(h, fh) : Float::INFINITY }.first
      family = chroma_tiebreak(family, l, c)
      @families[family].min_by { |t| (t[:lch][0] - l)**2 + (t[:lch][1] - c)**2 }[:hex]
    end
  end

  def chroma_tiebreak(family, l, c)
    muted_peer = @muted_peers.key(family)  # e.g. 'orange' → 'brown'
    return family unless muted_peer && @muted[muted_peer]

    chromatic_nearest = @families[family].min_by { |t| (t[:lch][0] - l).abs }
    muted_nearest     = @muted[muted_peer].min_by { |t| (t[:lch][0] - l).abs }

    (muted_nearest[:lch][1] - c).abs < (chromatic_nearest[:lch][1] - c).abs ? muted_peer : family
  end

  def hue_dist(a, b)
    d = (a - b).abs
    d > 180 ? 360 - d : d
  end

  def circular_mean(hues)
    sin_sum = hues.sum { |h| Math.sin(h * Math::PI / 180) }
    cos_sum = hues.sum { |h| Math.cos(h * Math::PI / 180) }
    (Math.atan2(sin_sum, cos_sum) * 180 / Math::PI) % 360
  end

  def self.hex_to_oklch(hex)
    lab = hex_to_oklab(hex)
    return nil unless lab
    _, a, b = lab
    c = Math.sqrt(a**2 + b**2)
    h = (Math.atan2(b, a) * 180 / Math::PI) % 360
    [lab[0], c, h]
  end

  def self.hex_to_oklab(hex)
    h = hex.delete_prefix('#').downcase
    return nil unless h.length == 6 && h.match?(/\A[0-9a-f]{6}\z/)

    r = linearize(h[0, 2].to_i(16) / 255.0)
    g = linearize(h[2, 2].to_i(16) / 255.0)
    b = linearize(h[4, 2].to_i(16) / 255.0)

    lm = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    mm = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    sm = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    lm, mm, sm = [lm, mm, sm].map { |x| x < 0 ? -((-x)**(1.0 / 3)) : x**(1.0 / 3) }

    [
      0.2104542553 * lm + 0.7936177850 * mm - 0.0040720468 * sm,
      1.9779984951 * lm - 2.4285922050 * mm + 0.4505937099 * sm,
      0.0259040371 * lm + 0.7827717662 * mm - 0.8086757660 * sm
    ]
  end

  def self.linearize(c)
    c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
  end
end
