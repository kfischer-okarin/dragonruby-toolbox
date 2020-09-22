# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

# Require this file to add support for colors to the attr_sprite class macro
module AttrSprite
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
