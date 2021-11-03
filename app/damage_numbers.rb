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

    @animation = BoF3StyleDamage.new(
      x: 640, y: 360,
      amount: (rand * 255).ceil,
      digit_sprites: (0..9).map { |k| GoodNeighborsFont.digit_sprite(k) }
    )
  end

  class BoF3StyleDamage
    def initialize(x:, y:, amount:, digit_sprites:)
      @x = x
      @y = y
      @digits = split_into_digits(amount)
      @digit_sprites = digit_sprites

      @current_x = x
      @current_y = y
      @current_digits = @digits
      @tick_count = 0
    end

    def tick
      @tick_count += 1
    end

    def finished?
      @tick_count > 60
    end

    def primitive_marker
      :sprite
    end

    def draw_override(ffi_draw)
      @current_digits.each_with_index do |digit, index|
        draw_digit(ffi_draw, digit, index)
      end
    end

    def draw_digit(ffi_draw, digit, index)
      sprite = @digit_sprites[digit]

      # center digit
      @digit_w ||= @digit_sprites.map(&:w).max
      x = @current_x + index * @digit_w + (@digit_w - sprite.w).idiv(2)

      ffi_draw.draw_sprite_3(
        x, @current_y, sprite.w, sprite.h,
        sprite.path,
        sprite.angle,
        sprite.a, sprite.r, sprite.g, sprite.b,
        sprite.tile_x, sprite.tile_y, sprite.tile_w, sprite.tile_h,
        sprite.flip_horizontally, sprite.flip_vertically,
        sprite.angle_anchor_x, sprite.angle_anchor_y,
        sprite.source_x, sprite.source_y, sprite.source_w, sprite.source_h
      )
    end

    private

    def split_into_digits(amount)
      remainder = amount
      [].tap { |digits|
        while remainder.positive?
          digits.insert(0, remainder % 10)
          remainder = remainder.idiv 10
        end
      }
    end
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
