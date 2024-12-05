# Copyright (c) 2022 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  module Animation
    class Parallel
      def initialize(*animations)
        @animations = animations
        @finished = false
      end

      def tick
        return if @finished

        @animations.each do |animation|
          animation.tick unless animation.finished?
        end
        @finished = @animations.all?(&:finished?)
      end

      def finished?
        @finished
      end
    end
  end
end
