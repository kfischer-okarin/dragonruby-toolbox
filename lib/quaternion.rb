# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  # Quaternion used to represent a rotation in 3D space
  #
  # @example Rotating an object by 120 degrees around the axis defined by vector (0, 1, 1)
  #   rotation = DRT::Quaternion.from_angle_and_axis(120.to_radians, 0, 1, 1)
  #   rotation.apply_to(my_object) # my_object must have getters/setters for x, y, z
  class Quaternion
    attr_reader :a, :b, :c, :d

    def initialize(a, b, c, d) # Naming/MethodParameterName
      @a = a
      @b = b
      @c = c
      @d = d
    end

    def self.from_angle_and_axis(angle, x, y, z) # rubocop:disable Metrics/AbcSize, Naming/MethodParameterName
      length = Math.sqrt(x**2 + y**2 + z**2)
      sinus = Math.sin(angle / 2)

      new(
        Math.cos(angle / 2),
        x * sinus / length,
        y * sinus / length,
        z * sinus / length
      )
    end

    def apply_to(vector)
      vector_quaternion = Quaternion.new(0, vector.x, vector.y, vector.z)
      result = self * vector_quaternion * inverse
      vector.x = result.b
      vector.y = result.c
      vector.z = result.d
    end

    def square_norm
      @a**2 + @b**2 + @c**2 + @d**2
    end

    def *(other) # rubocop:disable Metrics/AbcSize
      Quaternion.new(
        @a * other.a - @b * other.b - @c * other.c - @d * other.d,
        @a * other.b + @b * other.a + @c * other.d - @d * other.c,
        @a * other.c - @b * other.d + @c * other.a + @d * other.b,
        @a * other.d + @b * other.c - @c * other.b + @d * other.a
      )
    end

    def inverse
      return @inverse if @inverse

      factor = 1 / square_norm
      @inverse = Quaternion.new(@a * factor, -@b * factor, -@c * factor, -@d * factor)
    end

    def serialize
      "DRT::Quaternion(#{@a}, #{@b}, #{@c}, #{@d})"
    end

    def to_s
      serialize
    end

    def inspect
      serialize
    end
  end
end
