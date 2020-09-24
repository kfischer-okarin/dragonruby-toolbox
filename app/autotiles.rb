# require 'lib/low_resolution_canvas.rb'

class AutotileExample
  GRASS_AUTOTILE = DRT::Autotile::TileSource.new('sprites/grass-autotile.png', 32)

  ALL_DIRECTIONS = [[0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]]

  def tick(args)
    args.state.initialized ||= { tileset: false }
    args.state.tiles ||= {}
    args.state.neighbors ||= {}
    if !args.state.initialized[:tileset]
      args.render_target(:tileset).sprites << DRT::Autotile.generate_tileset_47(GRASS_AUTOTILE)
      args.state.initialized[:tileset] = true
      args.state.tile = DRT::Autotile::Tile.new(:tileset, GRASS_AUTOTILE.size)
    else
      mouse = args.inputs.mouse
      tile_coord = [mouse.point.x.idiv(32), mouse.point.y.idiv(32)]
      if mouse.button_left && !args.state.tiles.key?(tile_coord)
        args.state.tiles[tile_coord] = true
        ALL_DIRECTIONS.each do |direction|
          neighbor_coord = [tile_coord.x + direction.x, tile_coord.y + direction.y]
          args.state.neighbors[neighbor_coord] ||= 0
          args.state.neighbors[neighbor_coord] |= DRT::Autotile.bitmask([-direction.x, -direction.y])
        end
      end
      if mouse.button_right && args.state.tiles.key?(tile_coord)
        args.state.tiles.delete tile_coord
        ALL_DIRECTIONS.each do |direction|
          neighbor_coord = [tile_coord.x + direction.x, tile_coord.y + direction.y]
          args.state.neighbors[neighbor_coord] ||= 0
          args.state.neighbors[neighbor_coord] &= (255 - DRT::Autotile.bitmask([-direction.x, -direction.y]))
        end
      end
      args.outputs.sprites << args.state.tiles.keys.map { |coord|
        bitmask = args.state.neighbors[coord] || 0
        args.state.tile.render(bitmask).merge(x: coord.x * 32, y: coord.y * 32, w: 32, h: 32)
      }
    end
  end
end
