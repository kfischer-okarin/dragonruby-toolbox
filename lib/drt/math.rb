module DRT
  module Math
    # Calculates a parabola going through the given points.
    class Parabola
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Naming/MethodParameterName
      def initialize(p1, p2, p3)
        denom = (p1.x - p2.x) * (p1.x - p3.x) * (p2.x - p3.x)
        @a = (
          p3.x * (p2.y - p1.y) +
          p2.x * (p1.y - p3.y) +
          p1.x * (p3.y - p2.y)
        ) / denom
        @b = (
          p3.x * p3.x * (p1.y - p2.y) +
          p2.x * p2.x * (p3.y - p1.y) +
          p1.x * p1.x * (p2.y - p3.y)
        ) / denom
        @c = (
          p2.x * p3.x * (p2.x - p3.x) * p1.y +
          p3.x * p1.x * (p3.x - p1.x) * p2.y +
          p1.x * p2.x * (p1.x - p2.x) * p3.y
        ) / denom
        @start = [p1, p2, p3].min_by(&:x)
        @end = [p1, p2, p3].max_by(&:x)
      end

      def y(x)
        @a * x * x + @b * x + @c
      end

      # Returns the point between the start (left most x) and end (right most x)
      # for the given t (between 0 and 1)
      def point_at_t(t)
        x = @start.x + (t * (@end.x - @start.x)).ceil
        [x, y(x)]
      end
    end
  end
end
