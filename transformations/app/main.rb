require 'app/transformations.rb'

# Subclass Transformations::Base to create your own transformation
# This one simulates a moveable camera.
class Camera < Transformations::Base
  def initialize(origin)
    @origin = origin
  end

  def move_by(movement)
    @origin = [@origin.x + movement.x, @origin.y + movement.y]
  end

  # Overwrite sprite properties you want to transform
  # All other properties are just forwarded
  def x(original)
    original.x - @origin.x
  end

  def y(original)
    original.y - @origin.y
  end
end

# Simple night filter
class NightFilter < Transformations::Base
  # Overwrite sprite properties you want to transform
  # All other properties are just forwarded
  def r(original)
    (original.r || 255) * 0.3
  end

  def g(original)
    (original.g || 255) * 0.3
  end

  def b(original)
    (original.b || 255) * 0.5
  end
end

def random_box
  { x: rand * 1180, y: rand * 620, w: rand * 100, h: rand * 100, r: rand * 255, g: rand * 255, b: rand * 255 }.solid
end

def tick(args)
  if args.tick_count.zero?
    args.render_target(:random_boxes).background_color = [126, 200, 80]
    args.render_target(:random_boxes).primitives << 50.map_with_index { random_box }
    $camera = Camera.new([0, 0])
    $night_filter = NightFilter.new
    args.state.night = false
  end

  args.outputs.primitives << [0, 20, 'Press arrow keys to move the camera'].label
  args.outputs.primitives << [0, 40, 'Press N to toggle night filter'].label

  # Pass everything you want to transform into the transformation object with *
  if args.state.night
    # You can combine several transformations. They will be applied from right to left,
    # though in this case it doesn't really make any difference
    args.outputs.sprites << $camera * $night_filter * [0, 0, 1280, 720, :random_boxes]
  else
    args.outputs.sprites << $camera * [0, 0, 1280, 720, :random_boxes]
  end

  if args.inputs.keyboard.directional_vector
    $camera.move_by([args.inputs.keyboard.directional_vector.x * 10, args.inputs.keyboard.directional_vector.y * 10])
  end

  if args.inputs.keyboard.key_down.n
    args.state.night = !args.state.night
  end
end
