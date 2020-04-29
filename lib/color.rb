class Color
  def initialize(r, g, b, a = nil)
    @color = [r, g, b, a || 255]
  end

  def r
    @color[0]
  end

  def g
    @color[1]
  end

  def b
    @color[2]
  end

  def a
    @color[3]
  end

  # Support splat operator
  def to_a
    @color
  end

  def to_h
    { r: r, g: g, b: b, a: a }
  end

  class << self
    def from_hsv(h, s, v)
      c = v * s
      x = c * (1 - (h / 60.0 % 2 - 1).abs)
      m = v - c
      r, g, b = case h
                when 0...60
                  [c, x, 0]
                when 60...120
                  [x, c, 0]
                when 120...180
                  [0, c, x]
                when 180...240
                  [0, x, c]
                when 240...300
                  [x, 0, c]
                when 300...360
                  [c, 0, x]
                end
      new (r + m) * 255.0, (g + m) * 255.0, (b + m) * 255.0
    end

    def from_hsl(h, s, l)
      c = (1 - (2 * l - 1).abs) * s
      x = c * (1 - (h / 60.0 % 2 - 1).abs)
      m = l - c / 2
      r, g, b = case h
                when 0...60
                  [c, x, 0]
                when 60...120
                  [x, c, 0]
                when 120...180
                  [0, c, x]
                when 180...240
                  [0, x, c]
                when 240...300
                  [x, 0, c]
                when 300...360
                  [c, 0, x]
                end
      new (r + m) * 255.0, (g + m) * 255.0, (b + m) * 255.0
    end
  end
end
