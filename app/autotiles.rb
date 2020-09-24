# require 'lib/low_resolution_canvas.rb'

class AutotileExample
  GRASS_AUTOTILE = DRT::Autotile::TileSource.new('sprites/grass-autotile.png', 32)

  def tick(args)
    args.state.initialized ||= { tileset: false }
    if !args.state.initialized[:tileset]
      args.render_target(:tileset).sprites << DRT::Autotile.generate_tileset_47(GRASS_AUTOTILE)
      args.state.initialized[:tileset] = true
    else
      args.outputs.sprites << {
        x: 0, y: 0, w: 512, h: 512, source_w: 512, source_h: 512, source_x: 0, source_y: 0, path: :tileset
      }
    end
  end
end
