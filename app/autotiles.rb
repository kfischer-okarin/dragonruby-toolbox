# require 'lib/low_resolution_canvas.rb'

# rubocop:disable all
class AutotileExample
  TILE_SIZE = 32
  RENDER_SIZE = 32

  def tick(args)
    # Uncomment to use a handmade 47-tile tileset
    # args.state.tile ||= DRT::Autotile.new('sprites/autotile-tileset.png', TILE_SIZE)
    args.state.tile ||= DRT::Autotile.new(:tileset, TILE_SIZE)
    args.state.initialized ||= { tileset: false }
    args.state.tiles ||= {}
    if !args.state.initialized[:tileset]
      create_tileset(args)
      args.state.initialized[:tileset] = true
    else
      mouse = args.inputs.mouse
      tile_coord = [mouse.point.x.idiv(RENDER_SIZE), mouse.point.y.idiv(RENDER_SIZE)]
      if mouse.button_left && !args.state.tiles.key?(tile_coord)
        args.state.tiles[tile_coord] = initialize_tile_instance(args, tile_coord)
        add_tile_as_neighbor_of_all_neighbors(args, tile_coord)
      end
      if mouse.button_right && args.state.tiles.key?(tile_coord)
        args.state.tiles.delete tile_coord
        remove_tile_as_neighbor_of_all_neighbors(args, tile_coord)
      end
      args.outputs.sprites << args.state.tiles.values
    end
  end

  ALL_DIRECTIONS = [[0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]]

  def create_tileset(args)
    tileset_primitives = DRT::Autotile.generate_tileset_primitives('sprites/grass-autotile.png', TILE_SIZE)
    args.render_target(:tileset).primitives << tileset_primitives
  end

  def each_neighbor(args, tile_coord)
    ALL_DIRECTIONS.each do |direction|
      neighbor_coord = [tile_coord.x + direction.x, tile_coord.y + direction.y]
      next unless args.state.tiles.key? neighbor_coord

      yield neighbor_coord, direction
    end
  end

  def initialize_tile_instance(args, tile_coord)
    args.state.tile.create_instance(x: tile_coord.x * RENDER_SIZE, y: tile_coord.y * RENDER_SIZE, w: RENDER_SIZE, h: RENDER_SIZE).tap { |tile_instance|
      each_neighbor(args, tile_coord) do |neighbor_coord, direction|
        tile_instance.neighbors += direction
      end
    }
  end

  def add_tile_as_neighbor_of_all_neighbors(args, tile_coord)
    each_neighbor(args, tile_coord) do |neighbor_coord, direction|
      args.state.tiles[neighbor_coord].neighbors += [-direction.x, -direction.y]
    end
  end

  def remove_tile_as_neighbor_of_all_neighbors(args, tile_coord)
    each_neighbor(args, tile_coord) do |neighbor_coord, direction|
      args.state.tiles[neighbor_coord].neighbors -= [-direction.x, -direction.y]
    end
  end
end
