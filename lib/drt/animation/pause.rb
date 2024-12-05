# Copyright (c) 2022 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  module Animation
    class Pause
      def initialize(duration)
        @duration = duration
        @ticks = 0
      end

      def tick
        return if finished?

        @ticks += 1
      end

      def finished?
        @ticks >= @duration
      end
    end
  end
end
