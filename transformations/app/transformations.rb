module Transformations
  class Transformed
    attr_reader :original, :transformation

    def initialize(original, transformation)
      @original = original
      @transformation = transformation
    end

    def primitive_marker
      original.primitive_marker || :sprite
    end

    %i[
      x y w h path angle a r g b source_x source_y source_w source_h tile_x tile_y tile_h tile_w flip_horizontally flip_vertically
      angle_anchor_x angle_anchor_y
    ].each do |method|
      define_method method do
        return original.send(method) unless transformation.respond_to? method

        transformation.send(method, original)
      end
    end

    def *(primitive)
      @original = @original * primitive
      self
    end
  end

  class Base
    def *(sprite)
      Transformed.new(sprite, self)
    end
  end
end
