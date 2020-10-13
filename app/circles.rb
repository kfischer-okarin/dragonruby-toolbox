# require 'lib/circle.rb'

# rubocop:disable all
class CirclesExample
  def tick(args)
    args.state.canvas ||= DRT::LowResolutionCanvas.new([128, 72])
    args.state.circle ||= { diameter: 10, filled: false }
    circle = args.state.circle
    primitive = circle_primitive(circle[:diameter])
    if circle[:filled]
      args.state.canvas.primitives << DRT::Circle.solid(args, primitive)
    else
      args.state.canvas.primitives << DRT::Circle.border(args, primitive)
    end
    args.outputs.primitives << args.state.canvas

    if args.inputs.keyboard.key_down.up
      args.state.circle[:diameter] += 1
    end
    if args.inputs.keyboard.key_down.down
      args.state.circle[:diameter] -= 1
    end
    if args.inputs.keyboard.key_down.space
      args.state.circle[:filled] = !args.state.circle[:filled]
    end

    args.outputs.labels << [0, 20, "Diameter: #{args.state.circle[:diameter]}"]
    args.outputs.labels << [0, 40, "Filled? #{args.state.circle[:filled]}"]
  end

  def circle_primitive(diameter)
    {
      x: (128 - diameter).idiv(2),
      y: (72 - diameter).idiv(2),
      diameter: diameter,
      r: 255,
      g: 0,
      b: 0,
      a: 255
    }
  end
end
