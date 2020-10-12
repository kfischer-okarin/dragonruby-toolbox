# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  module Transformations
    # Primitive wrapper which returns transformed primitive values
    class Transformed
      attr_sprite

      attr_reader :original, :transformation

      def initialize(original, transformation)
        @original = original
        @transformation = transformation
      end

      def primitive_marker
        original.primitive_marker || :sprite
      end

      %i[
        x y w h path angle a r g b source_x source_y source_w source_h tile_x tile_y tile_h tile_w
        flip_horizontally flip_vertically
        angle_anchor_x angle_anchor_y
        text size_enum alignment_enum font
        x2 y2
      ].each do |method|
        define_method method do
          return original.send(method) unless transformation.respond_to? method

          transformation.send(method, original)
        end
      end

      def *(other)
        @original *= other
        self
      end
    end

    # Base class for transformations
    class Base
      def *(other)
        return other.map { |p| self * p } if Base.array_but_no_primitive? other

        Transformed.new(other, self)
      end

      def self.array_but_no_primitive?(value)
        value.is_a?(Array) && !value[0].is_a?(Numeric)
      end
    end
  end
end
