class DamageNumbersExample
  def tick(args)
    digit_sprite = digit_sprite(9)
    digit_sprite.x = 100
    digit_sprite.y = 100
    args.outputs.primitives << { x: digit_sprite.x, y: digit_sprite.y, w: digit_sprite.w, h: digit_sprite.h, r: 255, g: 0, b: 0 }.solid!
    args.outputs.primitives << digit_sprite
  end

  private

  SIZE_FACTOR = 10

  # Good Neighbors font by Clint Bellanger
  # https://opengameart.org/content/good-neighbors-pixel-font
  DIGIT_SPRITE_BASE = { h: 12 * SIZE_FACTOR, source_y: 3, source_h: 12, path: 'sprites/good_neighbors.png' }.freeze

  POSITIONS = {
    0 => { source_x: 130, source_w: 8 },
    1 => { source_x: 139, source_w: 6 },
    2 => { source_x: 146, source_w: 8 },
    3 => { source_x: 155, source_w: 8 },
    4 => { source_x: 164, source_w: 9 },
    5 => { source_x: 174, source_w: 8 },
    6 => { source_x: 183, source_w: 8 },
    7 => { source_x: 192, source_w: 8 },
    8 => { source_x: 201, source_w: 8 },
    9 => { source_x: 210, source_w: 8 }
  }.freeze

  def digit_sprite(digit)
    DIGIT_SPRITE_BASE.to_sprite(POSITIONS[digit]).tap { |result|
      result[:w] = result[:source_w] * SIZE_FACTOR
    }
  end
end
