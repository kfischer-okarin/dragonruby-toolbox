# require 'lib/low_resolution_canvas.rb'

class AutotileExample
  GRASS_AUTOTILE = DRT::Autotile::TileSource.new('sprites/grass-autotile.png', 32)

  def tick(args)
    args.state.initialized ||= { tileset: false }
    if !args.state.initialized[:tileset]
      args.render_target(:tileset).sprites << DRT::Autotile.generate_tileset_47(GRASS_AUTOTILE)
      args.state.initialized[:tileset] = true
      args.state.tile = DRT::Autotile::Tile.new(:tileset, GRASS_AUTOTILE.size)
    else
      args.outputs.sprites << [
        args.state.tile.render(0b01010101)
      ]
    end
  end
end
