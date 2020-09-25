# require 'lib/low_resolution_canvas.rb'

class AutotileExample
  TILE_SIZE = 32

  def tick(args)
    # Uncomment to use a handmade 47-tile tileset
    # args.state.tile ||= DRT::Autotile.new('sprites/autotile-tileset.png', TILE_SIZE)
    args.state.tile ||= DRT::Autotile.new(:tileset, TILE_SIZE)
    args.state.initialized ||= { tileset: false }
    args.state.tiles ||= {}
    args.state.neighbors ||= {}
    if !args.state.initialized[:tileset]
      create_tileset(args)
      args.state.initialized[:tileset] = true
    else
      mouse = args.inputs.mouse
      tile_coord = [mouse.point.x.idiv(32), mouse.point.y.idiv(32)]
      if mouse.button_left && !args.state.tiles.key?(tile_coord)
        args.state.tiles[tile_coord] = true
        add_tile_as_neighbor_of_all_neighbors(args, tile_coord)
      end
      if mouse.button_right && args.state.tiles.key?(tile_coord)
        args.state.tiles.delete tile_coord
        remove_tile_as_neighbor_of_all_neighbors(args, tile_coord)
      end
      render_tiles(args)
    end
  end

  ALL_DIRECTIONS = [[0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]]

  def create_tileset(args)
    tileset_primitives = DRT::Autotile.generate_tileset_primitives(path: 'sprites/grass-autotile.png', size: TILE_SIZE)
    args.render_target(:tileset).primitives << tileset_primitives
  end

  def add_tile_as_neighbor_of_all_neighbors(args, tile_coord)
    ALL_DIRECTIONS.each do |direction|
      neighbor_coord = [tile_coord.x + direction.x, tile_coord.y + direction.y]
      args.state.neighbors[neighbor_coord] ||= DRT::Autotile::Neighbors.new
      args.state.neighbors[neighbor_coord] += [-direction.x, -direction.y]
    end
  end

  def remove_tile_as_neighbor_of_all_neighbors(args, tile_coord)
    ALL_DIRECTIONS.each do |direction|
      neighbor_coord = [tile_coord.x + direction.x, tile_coord.y + direction.y]
      args.state.neighbors[neighbor_coord] ||= DRT::Autotile::Neighbors.new
      args.state.neighbors[neighbor_coord] -= [-direction.x, -direction.y]
    end
  end

  def render_tiles(args)
    args.outputs.sprites << args.state.tiles.keys.map { |coord|
      neighbors = args.state.neighbors[coord] || DRT::Autotile::Neighbors.new
      args.state.tile.render(neighbors).merge(x: coord.x * 32, y: coord.y * 32)
    }
  end
end
