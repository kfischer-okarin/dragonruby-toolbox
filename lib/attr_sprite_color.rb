# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

# Including this file will automatically extend the attr_sprite class macro

module DRT
  # Adds support for color objects to attr_sprite enhanced classes
  module AttrSpriteColor
    attr_accessor :color

    def r
      @r || @color&.r
    end

    def g
      @g || @color&.g
    end

    def b
      @b || @color&.b
    end

    def a
      @a || @color&.a
    end
  end
end

AttrSprite.prepend DRT::AttrSpriteColor
