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
    class Lufia2Style
      def initialize(x:, y:, amount:, digit_sprites:)
        @x = x
        @y = y
        @digits = split_into_digits(amount)
        @digit_sprites = digit_sprites

        @digit_y = [y] * @digits.size
        @alpha = 0
        @tick_count = 0
        @jump_height = (@digits[0] * 1.9).floor
        # @animation = Animation::Sequential.new(

        # )
      end

      SHOW_DURATION = 3
      ANIMATION_END = 74

      def tick
        if @tick_count < SHOW_DURATION
          show_damage
        elsif @tick_count == SHOW_DURATION
          start_bounce
        end


        @tick_count += 1
      end

      def finished?
        @tick_count > ANIMATION_END
      end

      def primitive_marker
        :sprite
      end

      def draw_override(ffi_draw)
        @digits.each_with_index do |digit, index|
          draw_digit(ffi_draw, digit, index)
        end
      end

      def draw_digit(ffi_draw, digit, index)
        sprite = @digit_sprites[digit]

        # center digit
        @digit_w ||= @digit_sprites.map(&:w).max
        x = @x + index * @digit_w + (@digit_w - sprite.w).idiv(2)

        ffi_draw.draw_sprite_3(
          x, @digit_y[index], sprite.w, sprite.h,
          sprite.path,
          sprite.angle,
          @alpha * (sprite.a || 255), sprite.r, sprite.g, sprite.b,
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

      def show_damage
        @alpha = (1.0 / SHOW_DURATION) * (@tick_count + 1)
      end

      def start_bounce
        # @bounce1 = Math::Parabola.new(
        #   [@x, @y],
        #   [@x + 1, @y + @jump_height]
        #   [@x + 2, @y]
        # )
        # @bounce2 = Math::Parabola.new(
        #   [@x, @y],
        #   [@x + 1, @y + @jump_height.idiv(2)]
        #   [@x + 2, @y]
        # )
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
