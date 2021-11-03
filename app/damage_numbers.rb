require 'lib/drt/damage_numbers/bof3_style.rb'

class DamageNumbersExample
  def tick(args)
    if @animation
      play_animation(args)
    else
      start_animation_on_space(args)
    end
  end

  private

  def play_animation(args)
    args.outputs.primitives << @animation
    @animation.tick
    @animation = nil if @animation.finished?
  end

  def start_animation_on_space(args)
    return unless args.inputs.keyboard.key_down.space

    @animation = DRT::DamageNumbers::BoF3Style.new(
      x: 640, y: 360,
      amount: (rand * 255).ceil,
      digit_sprites: (0..9).map { |k| GoodNeighborsFont.digit_sprite(k) },
      fall_height: 90 # 2.5 times the height of the font
    )
  end

  # Produces digit sprites from the Good Neighbors sprite sheet
  module GoodNeighborsFont
    def self.digit_sprite(digit)
      DIGIT_SPRITE_BASE.to_sprite(POSITIONS[digit]).tap { |result|
        result[:w] = result[:source_w] * SIZE_FACTOR
      }
    end

    SIZE_FACTOR = 3

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
  end
end
