# Copyright (c) 2022 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  module Animation
    class Sequential
      def initialize(*animations)
        @animations = animations
        @index = 0
        @current_animation = @animations[@index]
      end

      def tick
        return if finished?

        @current_animation.tick
        if @current_animation.finished?
          @index += 1
          @current_animation = @animations[@index]
        end
      end

      def finished?
        @index >= @animations.size
      end
    end
  end
end
