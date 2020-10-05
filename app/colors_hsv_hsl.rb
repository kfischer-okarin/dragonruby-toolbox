# require 'lib/color.rb'

# rubocop:disable all
class ColorsHsvHslExample
  def tick(args)
    args.state.type ||= :hsv
    args.state.value ||= 1.0

    refresh_wheel(args) if args.tick_count.zero?

    args.outputs.sprites << [0, 0, 1280, 720, :wheel]

    if args.inputs.keyboard.key_down.up
      args.state.value = [(args.state.value + 0.1), 1.0].min
      refresh_wheel(args)
    end
    if args.inputs.keyboard.key_down.down
      args.state.value = [(args.state.value - 0.1), 0.0].max
      refresh_wheel(args)
    end

    case args.state.type
    when :hsv
      args.outputs.labels << [10, 700, "HSV (Press Tab to toggle)"]
      args.outputs.labels << [10, 680, "Value #{args.state.value} (Press up/down to adjust)"]
      if input_toggle?(args)
        args.state.type = :hsl
        args.state.value = 0.5
        refresh_wheel(args)
      end
    when :hsl
      args.outputs.labels << [10, 700, "HSL (Press Tab to toggle)"]
      args.outputs.labels << [10, 680, "Lightness #{args.state.value} (Press up/down to adjust)"]
      if input_toggle?(args)
        args.state.type = :hsv
        args.state.value = 1.0
        refresh_wheel(args)
      end
    end
    args.outputs.labels << {
      x: args.grid.right,
      y: args.grid.top,
      alignment_enum: 2,
      text: "#{$gtk.args.gtk.current_framerate.to_i}"
    }
  end

  def input_toggle?(args)
    args.inputs.keyboard.key_down.tab
  end

  def deg_to_rad(deg)
    2 * Math::PI * deg / 360.0
  end

  def color_wheel(center = [640, 360], inner_radius = 50, outer_radius = 350, angle_steps = 360, radius_steps = 10)
    angle_step_size = 360.0 / angle_steps
    radius_percentage_step_size = 1.0 / radius_steps
    radius_step_size = (outer_radius - inner_radius).to_f / radius_steps

    # Enumerate the angles
    angle_steps.map_with_index { |i|
      deg = i * angle_step_size
      rad = deg_to_rad(deg)
      x = Math.sin(rad)
      y = Math.cos(rad)

      # Enumerate the line segments from center to outside
      radius_steps.map_with_index { |j|
        radius_percentage = (j + 1) * radius_percentage_step_size
        segment_start = inner_radius + radius_step_size * j
        segment_end = segment_start + radius_step_size
        color = yield deg, radius_percentage

        # You can use color with the splat (*) operator in your line/solid/border arrays to pass the rgb values
        [center.x + x * segment_start, center.y + y * segment_start, center.x + x * segment_end, center.y + y * segment_end, *color].line
      }
    }
  end

  def hsv_wheel(value)
    color_wheel { |deg, r|
      Color.from_hsv(deg, r, value)
    }
  end

  def hsl_wheel(value)
    color_wheel { |deg, r|
      Color.from_hsl(deg, r, value)
    }
  end

  def refresh_wheel(args)
    wheel = case args.state.type
            when :hsv
              hsv_wheel(args.state.value)
            when :hsl
              hsl_wheel(args.state.value)
            end
    args.render_target(:wheel).primitives << wheel
  end
end
