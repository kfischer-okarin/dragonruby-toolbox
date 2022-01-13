require 'lib/drt/damage_numbers/bof3_style.rb'

class DamageNumbersExample
  def initialize
    @style_index = 0
  end

  def tick(args)
    if @animation
      play_animation(args)
    else
      args.outputs.primitives << [10, 30, 'Press SPACE to show damage animation. Press number to change style'].label
      start_animation_on_space(args)
      handle_style_change(args)
    end
    print_style_choices(args)
  end

  private

  def play_animation(args)
    args.outputs.primitives << @animation
    @animation.tick
    @animation = nil if @animation.finished?
  end

  def start_animation_on_space(args)
    return unless args.inputs.keyboard.key_down.space

    @animation = STYLES[@style_index].build_animation.call (rand * 255).ceil
  end

  def handle_style_change(args)
    input_char = args.inputs.text[0]
    return unless ('0'..'9').include? input_char

    input_number = input_char.to_i - 1
    return unless input_number < STYLES.size

    @style_index = input_number
  end

  def print_style_choices(args)
    args.outputs.primitives << STYLES.map_with_index { |style, i|
      marker = @style_index == i ? '> ' : '  '
      {
        x: 10, y: 710 - (i * 30), text: "#{marker} #{i + 1}. #{style[:name]}"
      }.label!
    }
  end

  STYLES = [
    {
      name: 'Breath of Fire 3 Style',
      build_animation: lambda { |amount|
        DRT::DamageNumbers::BoF3Style.new(
          x: 640, y: 360,
          amount: amount,
          digit_sprites: (0..9).map { |k| GoodNeighborsFont.digit_sprite(k) },
          fall_height: 90 # 2.5 times the height of the font
        )
      }
    }
  ].freeze

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
