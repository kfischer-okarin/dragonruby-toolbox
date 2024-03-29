# Copyright (c) 2021-2022 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

require 'lib/drt/math.rb'

module DRT
  module DamageNumbers
    # Creates a Breath of Fire 3 style damage number animation
    #
    # @example Create a damage number animation
    #   animation = DRT::DamageNumbers::BoF3Style.new(
    #     x: enemy.x, y: enemy.y,
    #     amount: 999,
    #     digit_sprites: DIGIT_SPRITES,
    #     fall_height: 100
    #   )
    #
    #   # Every tick do something like
    #   unless animation.finished?
    #     args.outputs.primitives << animation
    #     animation.tick
    #   end
    #
    # @param x [Integer] Starting x position of the damage number
    # @param y [Integer] Starting y position of the damage number
    # @param amount [Integer] Amount of damage
    # @param digit_sprites [Array<Sprite>] Array of sprites for each digit (0 to 9)
    # @param fall_height [Integer] How far the damage number will fall.
    #   About 2.5 times the height of the digit sprites is close to the original
    #   animation.
    class BoF3Style
      def initialize(x:, y:, amount:, digit_sprites:, fall_height:)
        @x = x
        @y = y
        @digits = split_into_digits(amount)
        @digit_sprites = digit_sprites
        @fall_height = fall_height

        @current_x = x
        @current_y = y
        @current_digits = @digits
        @tick_count = 0
      end

      FALL_START = 20
      BOUNCE_START = 29
      BOUNCE_END = 51
      ANIMATION_END = 74

      def tick
        set_random_digits if @tick_count < BOUNCE_START && @tick_count.mod_zero?(2)
        set_original_digits if @tick_count == BOUNCE_START
        fall if @tick_count >= FALL_START && @tick_count < BOUNCE_START
        bounce if @tick_count >= BOUNCE_START && @tick_count < BOUNCE_END

        @tick_count += 1
      end

      def finished?
        @tick_count > ANIMATION_END
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

      def set_random_digits
        @current_digits = @digits.map { (rand * 10).floor }
      end

      def set_original_digits
        @current_digits = @digits
      end

      def fall
        @current_y = @y - (@fall_height * (@tick_count - FALL_START) / (BOUNCE_START - FALL_START))
      end

      def bounce
        @bounce_parabola ||= init_bounce_parabola
        t = (@tick_count - BOUNCE_START) / (BOUNCE_END - BOUNCE_START)
        @current_x, @current_y = @bounce_parabola.point_at_t(t)
      end

      def init_bounce_parabola
        fall_end = [@x, @y - @fall_height]
        bounce_end = [@x + @fall_height.idiv(4), @y - (@fall_height * 1.25).ceil]
        top = [(fall_end.x + bounce_end.x).idiv(2), @y - @fall_height.idiv(4)]
        Math::Parabola.new(fall_end, top, bounce_end)
      end
    end
  end
end
