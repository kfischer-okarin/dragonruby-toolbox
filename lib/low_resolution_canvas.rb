# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

class LowResolutionCanvas
  attr_sprite

  def initialize(resolution, render_target_name = :screen)
    @path = render_target_name
    @source_x, @source_y = [0, 0]
    @source_w, @source_h = resolution

    # Scale and center renter target to real screen size
    @w = @source_w * scale
    @h = @source_h * scale
    @x = ($args.grid.w - @w).idiv 2
    @y = ($args.grid.h - @h).idiv 2
  end

  def labels
    render_target.labels
  end

  def lines
    render_target.lines
  end

  def solids
    render_target.solids
  end

  def borders
    render_target.borders
  end

  def sprites
    render_target.sprites
  end

  def primitives
    render_target.primitives
  end

  def background_color=(color)
    render_target.background_color = color
  end

  def to_screen_point(point)
    [@x + point.x * scale, @y + point.y * scale]
  end

  def to_screen_rect(rect)
    [*to_screen_point(rect), rect.w * scale, rect.h * scale]
  end

  private

  def scale
    @scale ||= [$args.grid.w.idiv(@source_w), $args.grid.h.idiv(@source_h)].min
  end

  def render_target
    $args.render_target(@path)
  end
end
