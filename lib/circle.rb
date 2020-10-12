# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  # Pixel perfect circle drawing
  module Circle
    class << self
      def border(args, values)
        CircleBuilder.new(values, BorderRenderer).render(args)
      end

      def solid(args, values)
        CircleBuilder.new(values, SolidRenderer).render(args)
      end

      def used_render_targets
        @used_render_targets ||= Set.new
      end
    end

    class CircleBuilder
      def initialize(values, renderer_class)
        @values = values
        @radius = (values[:diameter] / 2).ceil
        @renderer_class = renderer_class
        @quarter_base = build_quarter_base
      end

      def render(args)
        return if prepare_render_target(args)

        [0, 90, 180, 270].map { |angle|
          @quarter_base.merge(angle: angle)
        }
      end

      private

      def build_quarter_base
        colors = @values.select { |key, _| %i[r g b a].include? key }
        {
          x: @radius + @values[:x], y: @radius + @values[:y], w: @radius, h: @radius,
          path: render_target_name,
          angle_anchor_x: 0, angle_anchor_y: 0
        }.merge(colors).sprite
      end

      def prepare_render_target(args)
        return false if Circle.used_render_targets.include? render_target_name

        target = args.render_target(render_target_name)
        target.width = @radius
        target.height = @radius
        target.primitives << render_quarter
        Circle.used_render_targets << render_target_name
        true
      end

      def render_target_name
        @render_target_name ||= :"#{@renderer_class.name}_#{@values[:diameter]}"
      end

      def render_quarter
        segment_lines = @renderer_class.new(@radius).lines
        segment_lines + reverse_xy(segment_lines)
      end

      def reverse_xy(lines)
        lines.map { |line| [line.y1 - 1, line.x1 + 1, line.y2 - 1, line.x2 + 1, line.r, line.g, line.b].line }
      end
    end

    class BorderRenderer
      attr_reader :lines

      def initialize(radius)
        @radius = radius
        @lines = []
        build
      end

      def build
        while line_needed?
          next_line = build_next_line
          if line_is_growing?(next_line)
            fix_lines(length(next_line))
            next
          end
          @lines << next_line
        end
      end

      def build_next_line
        last_line = @lines.last
        x = last_line ? last_line.x - 1 : @radius - 1
        y1 = last_line ? last_line.y2 : 0
        y2 = y1 + 1

        y2 += 1 while x**2 + y2**2 <= @radius**2
        [x, y1, x, y2, 255, 255, 255].line
      end

      def line_needed?
        return true if @lines.empty?

        last_line = @lines.last
        last_line.y1 <= last_line.x
      end

      def length(line)
        line.y2 - line.y1
      end

      def line_is_growing?(line)
        last_line = @lines.last
        return false unless last_line

        length(line) > length(last_line)
      end

      def fix_lines(min_length)
        index_of_first_shorter_line = @lines.find_index { |line| length(line) < min_length }
        @lines = @lines[0..index_of_first_shorter_line] # Drop all lines after that line
        @lines.last.y2 = @lines.last.y1 + min_length # Adjust it to the minimum length
      end
    end

    class SolidRenderer < BorderRenderer
      def build
        super
        @lines = @lines.flat_map { |line|
          (line.y1...line.y2).map { |y|
            [0, y, line.x + 1, y, 255, 255, 255].line
          }
        }
      end
    end

    class Set
      def initialize
        @values = {}
      end

      def <<(value)
        @values[value] = true
      end

      def include?(value)
        @values.key? value
      end
    end
  end
end
