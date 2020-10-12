# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  # Autotile that renders in different ways depending on how many neighbors have the same tiles
  class Autotile
    attr_reader :path, :size

    # Create a single autotile
    #
    # @example Creating an 32x32 autotile
    #   tile = DRT::Autotile.new('sprites/autotile-tileset.png', 32)
    #
    # @param path [String] Path to the tileset file
    #   The tileset should contain 47 tiles arranged in a 7x7 grid that cover all important neighbor combinations.
    #   See https://github.com/kfischer-okarin/dragonruby-toolbox/blob/master/sprites/autotile-tileset.png for an example of such a
    #   tileset.
    # @param size [Integer] The width/height of one tile in the tileset (assuming square tiles)
    # @param tileset_layout [TilesetLayout, nil] Custom tileset configuration (optional)
    #   Instead of the default tileset configuration you can specify your own custom tileset layout. By default {TILESET_47} is used.
    #   There is also a second configuration {FULL_TILESET} which specifies all 256 tiles for all neighbor combinations in a 16x16 grid.
    def initialize(path, size, tileset_layout = nil)
      @path = path
      @size = size
      @sprites = calc_sprites(tileset_layout || TILESET_47)
    end

    # Creates a renderable tile instance with all attr_sprite methods and a neighbors setter which will update the rendered tile.
    #
    # @example Create a tile instance
    #  tile.create_instance(x: 200, y: 200)
    #
    # @param initial_values [Hash] (optional) initial values for tile attributes (x, y, etc)
    def create_instance(initial_values = nil)
      values = initial_values || {}
      Instance.new(self).tap { |instance|
        values.each do |attribute, value|
          instance.send(:"#{attribute}=", value)
        end
      }
    end

    # Renders the tile sprite for the specified neighbor combination as hash primitive
    #
    # @example Render a map position
    #   ALL_DIRECTIONS = [[0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]]
    #
    #   neighbors = Neighbors.new
    #   ALL_DIRECTIONS.each do |direction|
    #     neighbor_position = map.neighbor_of(position, direction)
    #     neighbors += direction if map.tile_at(neighbor_position) == tile
    #   end
    #
    #   args.outputs.primitives << tile.render(neighbors)
    #
    # @param neighbors [Neighbors] Neighbor combination. Use your game's map data to calculate this value.
    # @return [Hash] Hash sprite primitive rendering the correct tile
    def render(neighbors)
      @sprites[neighbors]
    end

    # This class is used to specify which of the neighbors of the current tile are containing the same tile to determine the right tile
    # sprite to be rendered.
    #
    # Pass in directions as symbols (see {DIRECTIONS}) or as vectors (see {DIRECTION_VECTORS}).
    #
    # @example Specify neighbors with symbols
    #   Neighbors.new(:up_right, :right, :down_right)
    #
    # @example Specify neighbors with vectors
    #   Neighbors.new([0, 1], [0, -1])
    #
    # You can use the `+`` and `-` methods to calculate a new neighbors value by adding/removing the specified direction.
    #
    # @example Add a direction to a neighbors value
    #   neighbors = Neighbors.new(:up)
    #   new_neighbors = neighbors + :right # new_neighbors now contains :up and :right
    #
    class Neighbors
      # Map from direction name to bitmask
      DIRECTIONS = {
        up: 0b00000001, up_right: 0b00000010, right: 0b00000100, down_right: 0b00001000,
        down: 0b00010000, down_left: 0b00100000, left: 0b01000000, up_left: 0b10000000
      }.freeze
      # Map from vector to bitmask
      DIRECTION_VECTORS = {
        [0, 1] => 0b00000001, [1, 1] => 0b00000010, [1, 0] => 0b00000100, [1, -1] => 0b00001000,
        [0, -1] => 0b00010000, [-1, -1] => 0b00100000, [-1, 0] => 0b01000000, [-1, 1] => 0b10000000
      }.freeze

      class << self
        def new(*directions)
          bitmask = Bitmask.from(*directions)
          @values ||= {}
          @values[bitmask] ||= super(bitmask)
        end
      end

      def initialize(bitmask)
        @bitmask = bitmask
      end

      def +(other)
        other_bitmask = Bitmask.from(other)
        Neighbors.new(@bitmask | other_bitmask)
      end

      def -(other)
        other_bitmask = Bitmask.from(other)
        Neighbors.new(@bitmask & (255 - other_bitmask))
      end

      def include?(*directions)
        other_bitmask = Bitmask.from(*directions)
        @bitmask & other_bitmask == other_bitmask
      end

      def exclude?(*directions)
        other_bitmask = Bitmask.from(*directions)
        (@bitmask & other_bitmask).zero?
      end

      def serialize
        directions = DIRECTIONS.keys.select { |d| include? d }
        "Neighbors.new(#{directions.to_s[1..-2]})"
      end

      def inspect
        serialize
      end
    end

    # Renderable Autotile instance
    # It supports all attr_sprites methods and you can directly set and update the neighbors value on this object
    class Instance
      attr_accessor :x, :y, :w, :h, :r, :g, :b, :a, :angle, :flip_horizontally, :flip_vertically, :angle_anchor_x, :angle_anchor_y

      attr_reader :tile_x, :tile_y, :tile_w, :tile_h, :source_x, :source_y, :source_w, :source_h, :path,
                  :neighbors

      def initialize(tile)
        @tile = tile
        @w = @h = @source_w = @source_h = tile.size
        @path = tile.path

        self.neighbors = Neighbors.new
      end

      def neighbors=(value)
        rendered = @tile.render(value)
        @source_x = rendered[:source_x]
        @source_y = rendered[:source_y]
        @neighbors = value
      end

      def primitive_marker
        :sprite
      end
    end

    # Use a simpler autotile source image to generate a full tileset on the fly and save it in a render target.
    #
    # @param path [String] Path to the autotile source image file
    #   This source image a layout inspired by the RPG Maker tileset format.
    #   See https://github.com/kfischer-okarin/dragonruby-toolbox/blob/master/sprites/grass-autotile.png for an example of such an
    #   image.
    # @param size [Integer] The width/height of one tile in the tileset (assuming square tiles)
    # @param tileset_layout [TilesetLayout] (optional) Custom tileset layout used for generation
    #   See explanation in {#initialize}.
    def self.generate_tileset_primitives(path, size, tileset_layout = nil)
      TilesetBuilder.new(path, size, tileset_layout || TILESET_47).build_primitives
    end

    private

    def calc_sprites(tileset)
      tiles = {}
      (0..255).map { |bitmask|
        tile_position = tileset.tile_position_for(bitmask)
        tiles[tile_position] ||= tile_for_position(tile_position)
        [Neighbors.new(bitmask), tiles[tile_position]]
      }.to_h
    end

    def tile_for_position(position)
      {
        path: @path,
        w: @size,
        h: @size,
        source_x: position.x * @size,
        source_y: position.y * @size,
        source_w: @size,
        source_h: @size
      }.freeze
    end

    module Bitmask
      def self.from(*values)
        case values[0]
        when Integer
          values[0]
        when Array
          values.map { |v| Neighbors::DIRECTION_VECTORS[v] }.inject(0) { |sum, n| sum + n }
        when Symbol
          values.map { |v| Neighbors::DIRECTIONS[v] }.inject(0) { |sum, n| sum + n }
        when nil
          0
        else
          raise "Value '#{values}' cannot be converted to bitmask"
        end
      end
    end

    # Definition of tile parts that will make up the tiles in the end
    module TileParts # rubocop:disable Metrics/ModuleLength
      SINGLE_UP_LEFT = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:up, :left) && (n.exclude?(:right) || n.exclude?(:down)) }
      }.freeze
      SINGLE_UP_RIGHT = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:up, :right) && (n.exclude?(:left) || n.exclude?(:down)) }
      }.freeze
      SINGLE_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:down, :left) && (n.exclude?(:right) || n.exclude?(:up)) }
      }.freeze
      SINGLE_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:down, :right) && (n.exclude?(:left) || n.exclude?(:up)) }
      }.freeze

      PLUS_UP_LEFT = {
        tile_corner: :up_left,
        condition: ->(n) { n.include?(:up, :left) && n.exclude?(:up_left) }
      }.freeze
      PLUS_UP_RIGHT = {
        tile_corner: :up_right,
        condition: ->(n) { n.include?(:up, :right) && n.exclude?(:up_right) }
      }.freeze
      PLUS_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: ->(n) { n.include?(:down, :left) && n.exclude?(:down_left) }
      }.freeze
      PLUS_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: ->(n) { n.include?(:down, :right) && n.exclude?(:down_right) }
      }.freeze

      CORNER_UP_LEFT = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:up, :left) && n.include?(:right, :down) }
      }.freeze
      CORNER_UP_RIGHT = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:up, :right) && n.include?(:left, :down) }
      }.freeze
      CORNER_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:down, :left) && n.include?(:right, :up) }
      }.freeze
      CORNER_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:down, :right) && n.include?(:left, :up) }
      }.freeze

      UP_LEFT = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:up) && n.include?(:right) }
      }.freeze
      UP_RIGHT = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:up) && n.include?(:left) }
      }.freeze
      LEFT_UP = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:left) && n.include?(:down) }
      }.freeze
      RIGHT_UP = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:right) && n.include?(:down) }
      }.freeze
      LEFT_DOWN = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:left) && n.include?(:up) }
      }.freeze
      RIGHT_DOWN = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:right) && n.include?(:up) }
      }.freeze
      DOWN_LEFT = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:down) && n.include?(:right) }
      }.freeze
      DOWN_RIGHT = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:down) && n.include?(:left) }
      }.freeze

      CENTER_UP_LEFT = {
        tile_corner: :down_right,
        condition: ->(n) { n.include?(:right, :down, :down_right) }
      }.freeze
      CENTER_UP_RIGHT = {
        tile_corner: :down_left,
        condition: ->(n) { n.include?(:left, :down, :down_left) }
      }.freeze
      CENTER_DOWN_LEFT = {
        tile_corner: :up_right,
        condition: ->(n) { n.include?(:right, :up, :up_right) }
      }.freeze
      CENTER_DOWN_RIGHT = {
        tile_corner: :up_left,
        condition: ->(n) { n.include?(:left, :up, :up_left) }
      }.freeze

      # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets, Layout/ExtraSpacing
      PARTS = [
        [  SINGLE_UP_LEFT,   SINGLE_UP_RIGHT,      PLUS_UP_LEFT,     PLUS_UP_RIGHT].freeze,
        [SINGLE_DOWN_LEFT, SINGLE_DOWN_RIGHT,    PLUS_DOWN_LEFT,   PLUS_DOWN_RIGHT].freeze,
        [  CORNER_UP_LEFT,           UP_LEFT,          UP_RIGHT,   CORNER_UP_RIGHT].freeze,
        [         LEFT_UP,    CENTER_UP_LEFT,   CENTER_UP_RIGHT,          RIGHT_UP].freeze,
        [       LEFT_DOWN,  CENTER_DOWN_LEFT, CENTER_DOWN_RIGHT,        RIGHT_DOWN].freeze,
        [CORNER_DOWN_LEFT,         DOWN_LEFT,        DOWN_RIGHT, CORNER_DOWN_RIGHT].freeze
      ].freeze
      # rubocop:enable Layout/SpaceInsideArrayLiteralBrackets, Layout/ExtraSpacing

      def self.definitions_for(corner, part_size)
        [].tap { |result|
          PARTS.each.with_index do |row, y|
            row.each.with_index do |definition, x|
              next unless definition[:tile_corner] == corner

              result << {
                condition: definition[:condition],
                sprite: {
                  tile_x: part_size * x,
                  tile_y: part_size * y,
                  tile_w: part_size,
                  tile_h: part_size,
                }
              }
            end
          end
        }
      end
    end

    class TileBuilder
      def initialize(tile_size)
        @part_size = tile_size.idiv 2
        @up_left = TileParts.definitions_for(:up_left, @part_size)
        @up_right = TileParts.definitions_for(:up_right, @part_size)
        @down_left = TileParts.definitions_for(:down_left, @part_size)
        @down_right = TileParts.definitions_for(:down_right, @part_size)
      end

      def generate(value)
        base = { w: @part_size, h: @part_size }.sprite
        [
          base.merge(x: 0, y: 0).merge(matching_part(@down_left, value)),
          base.merge(x: @part_size, y: 0).merge(matching_part(@down_right, value)),
          base.merge(x: 0, y: @part_size).merge(matching_part(@up_left, value)),
          base.merge(x: @part_size, y: @part_size).merge(matching_part(@up_right, value))
        ]
      end

      private

      def matching_part(definitions, value)
        matched = definitions.find { |definition| definition[:condition].call Neighbors.new(value) }
        matched[:sprite]
      end
    end

    module Tiles # rubocop:disable Metrics/ModuleLength
      CORNER_UP_LEFT = {
        value: Bitmask.from(:right, :down_right, :down),
        forbidden: Bitmask.from(:up, :left)
      }.freeze
      CORNER_UP_RIGHT = {
        value: Bitmask.from(:left, :down_left, :down),
        forbidden: Bitmask.from(:up, :right)
      }.freeze
      CORNER_DOWN_LEFT = {
        value: Bitmask.from(:right, :up_right, :up),
        forbidden: Bitmask.from(:down, :left)
      }.freeze
      CORNER_DOWN_RIGHT = {
        value: Bitmask.from(:left, :up_left, :up),
        forbidden: Bitmask.from(:down, :right)
      }.freeze

      SIDE_UP = {
        value: Bitmask.from(:left, :down_left, :down, :down_right, :right),
        forbidden: Bitmask.from(:up)
      }.freeze
      SIDE_DOWN = {
        value: Bitmask.from(:left, :up_left, :up, :up_right, :right),
        forbidden: Bitmask.from(:down)
      }.freeze
      SIDE_LEFT = {
        value: Bitmask.from(:up, :up_right, :right, :down_right, :down),
        forbidden: Bitmask.from(:left)
      }.freeze
      SIDE_RIGHT = {
        value: Bitmask.from(:up, :up_left, :left, :down_left, :down),
        forbidden: Bitmask.from(:right)
      }.freeze

      CENTER = {
        value: Bitmask.from(:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left)
      }.freeze

      CORNER_UP_LEFT_LINE_LEFT = {
        value: Bitmask.from(:left, :down, :down_right, :right),
        forbidden: Bitmask.from(:down_left, :up)
      }.freeze
      CORNER_UP_LEFT_LINE_UP = {
        value: Bitmask.from(:up, :down, :down_right, :right),
        forbidden: Bitmask.from(:up_right, :left)
      }.freeze
      CORNER_UP_RIGHT_LINE_UP = {
        value: Bitmask.from(:up, :left, :down_left, :down),
        forbidden: Bitmask.from(:up_left, :right)
      }.freeze
      CORNER_UP_RIGHT_LINE_RIGHT = {
        value: Bitmask.from(:right, :left, :down_left, :down),
        forbidden: Bitmask.from(:down_right, :up)
      }.freeze
      CORNER_DOWN_LEFT_LINE_DOWN = {
        value: Bitmask.from(:down, :right, :up_right, :up),
        forbidden: Bitmask.from(:down_right, :left)
      }.freeze
      CORNER_DOWN_LEFT_LINE_LEFT = {
        value: Bitmask.from(:left, :right, :up_right, :up),
        forbidden: Bitmask.from(:up_left, :down)
      }.freeze
      CORNER_DOWN_RIGHT_LINE_RIGHT = {
        value: Bitmask.from(:right, :up, :up_left, :left),
        forbidden: Bitmask.from(:up_right, :down)
      }.freeze
      CORNER_DOWN_RIGHT_LINE_DOWN = {
        value: Bitmask.from(:down, :up, :up_left, :left),
        forbidden: Bitmask.from(:down_left, :right)
      }.freeze

      CORNER_UP_LEFT_TWO_LINES = {
        value: Bitmask.from(:left, :up, :right, :down_right, :down)
      }.freeze
      CORNER_UP_RIGHT_TWO_LINES = {
        value: Bitmask.from(:right, :up, :left, :down_left, :down)
      }.freeze
      CORNER_DOWN_LEFT_TWO_LINES = {
        value: Bitmask.from(:left, :down, :right, :up_right, :up)
      }.freeze
      CORNER_DOWN_RIGHT_TWO_LINES = {
        value: Bitmask.from(:right, :down, :left, :up_left, :up)
      }.freeze

      SIDE_UP_LINE = {
        value: Bitmask.from(:left, :up, :right, :down_right, :down, :down_left)
      }.freeze
      SIDE_LEFT_LINE = {
        value: Bitmask.from(:up, :left, :down, :down_right, :right, :up_right)
      }.freeze
      SIDE_RIGHT_LINE = {
        value: Bitmask.from(:up, :right, :down, :down_left, :left, :up_left)
      }.freeze
      SIDE_DOWN_LINE = {
        value: Bitmask.from(:left, :down, :right, :up_right, :up, :up_left)
      }.freeze

      L_DOWN_RIGHT = {
        value: Bitmask.from(:right, :down),
        forbidden: Bitmask.from(:left, :up, :down_right)
      }.freeze
      L_DOWN_LEFT = {
        value: Bitmask.from(:left, :down),
        forbidden: Bitmask.from(:up, :right, :down_left)
      }.freeze
      L_UP_RIGHT = {
        value: Bitmask.from(:right, :up),
        forbidden: Bitmask.from(:left, :down, :up_right)
      }.freeze
      L_UP_LEFT = {
        value: Bitmask.from(:left, :up),
        forbidden: Bitmask.from(:right, :down, :up_left)
      }.freeze

      T_DOWN_LEFT_RIGHT = {
        value: Bitmask.from(:left, :down, :right),
        forbidden: Bitmask.from(:up, :down_left, :down_right)
      }.freeze
      T_UP_DOWN_RIGHT = {
        value: Bitmask.from(:right, :up, :down),
        forbidden: Bitmask.from(:left, :up_right, :down_right)
      }.freeze
      T_UP_DOWN_LEFT = {
        value: Bitmask.from(:left, :up, :down),
        forbidden: Bitmask.from(:right, :up_left, :down_left)
      }.freeze
      T_UP_LEFT_RIGHT = {
        value: Bitmask.from(:left, :up, :right),
        forbidden: Bitmask.from(:down, :up_left, :up_right)
      }.freeze

      PLUS = {
        value: Bitmask.from(:left, :right, :up, :down)
      }.freeze

      FAT_PLUS_UP_LEFT = {
        value: Bitmask.from(:left, :up, :up_right, :right, :down_right, :down, :down_left)
      }.freeze
      FAT_PLUS_UP_RIGHT = {
        value: Bitmask.from(:right, :up, :up_left, :left, :down_left, :down, :down_right)
      }.freeze
      FAT_PLUS_DOWN_LEFT = {
        value: Bitmask.from(:left, :down, :down_right, :right, :up_right, :up, :up_left)
      }.freeze
      FAT_PLUS_DOWN_RIGHT = {
        value: Bitmask.from(:right, :down, :down_left, :left, :up_left, :up, :up_right)
      }.freeze

      DIAGONAL_CONNECT_RIGHT = {
        value: Bitmask.from(:up, :up_right, :right, :down, :down_left, :left)
      }.freeze
      DIAGONAL_CONNECT_LEFT = {
        value: Bitmask.from(:up, :up_left, :left, :down, :down_right, :right)
      }.freeze

      VERTICAL_LINE_END_UP = {
        value: Bitmask.from(:down),
        forbidden: Bitmask.from(:up, :left, :right)
      }.freeze
      VERTICAL_LINE = {
        value: Bitmask.from(:up, :down),
        forbidden: Bitmask.from(:left, :right)
      }.freeze
      VERTICAL_LINE_END_DOWN = {
        value: Bitmask.from(:up),
        forbidden: Bitmask.from(:left, :down, :right)
      }.freeze

      HORIZONTAL_LINE_END_LEFT = {
        value: Bitmask.from(:right),
        forbidden: Bitmask.from(:up, :left, :down)
      }.freeze
      HORIZONTAL_LINE = {
        value: Bitmask.from(:left, :right),
        forbidden: Bitmask.from(:up, :down)
      }.freeze
      HORIZONTAL_LINE_END_RIGHT = {
        value: Bitmask.from(:left),
        forbidden: Bitmask.from(:up, :right, :down)
      }.freeze

      NO_NEIGHBORS = {
        value: 0,
        forbidden: Bitmask.from(:up, :down, :right, :left)
      }.freeze

      FULL_TILESET = (0...16).map { |row|
        start = row * 16
        (start...(start + 16)).map { |value|
          { value: value }.freeze
        }.freeze
      }.freeze

      # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets, Layout/ExtraSpacing, Layout/LineLength
      TILESET_47 = [
        [  CORNER_UP_LEFT_TWO_LINES,         SIDE_UP,   CORNER_UP_RIGHT_TWO_LINES,               L_DOWN_RIGHT,            T_DOWN_LEFT_RIGHT,                L_DOWN_LEFT,        VERTICAL_LINE_END_UP].freeze,
        [                 SIDE_LEFT,          CENTER,                  SIDE_RIGHT,            T_UP_DOWN_RIGHT,                         PLUS,             T_UP_DOWN_LEFT,               VERTICAL_LINE].freeze,
        [CORNER_DOWN_LEFT_TWO_LINES,       SIDE_DOWN, CORNER_DOWN_RIGHT_TWO_LINES,                 L_UP_RIGHT,              T_UP_LEFT_RIGHT,                  L_UP_LEFT,      VERTICAL_LINE_END_DOWN].freeze,
        [            CORNER_UP_LEFT,    SIDE_UP_LINE,             CORNER_UP_RIGHT,   CORNER_UP_LEFT_LINE_LEFT,      CORNER_UP_RIGHT_LINE_UP,     CORNER_UP_LEFT_LINE_UP,  CORNER_UP_RIGHT_LINE_RIGHT].freeze,
        [            SIDE_LEFT_LINE,             nil,             SIDE_RIGHT_LINE, CORNER_DOWN_LEFT_LINE_DOWN, CORNER_DOWN_RIGHT_LINE_RIGHT, CORNER_DOWN_LEFT_LINE_LEFT, CORNER_DOWN_RIGHT_LINE_DOWN].freeze,
        [          CORNER_DOWN_LEFT,  SIDE_DOWN_LINE,           CORNER_DOWN_RIGHT,           FAT_PLUS_UP_LEFT,            FAT_PLUS_UP_RIGHT,      DIAGONAL_CONNECT_LEFT,      DIAGONAL_CONNECT_RIGHT].freeze,
        [  HORIZONTAL_LINE_END_LEFT, HORIZONTAL_LINE,   HORIZONTAL_LINE_END_RIGHT,         FAT_PLUS_DOWN_LEFT,          FAT_PLUS_DOWN_RIGHT,                        nil,                NO_NEIGHBORS].freeze
      ].freeze
      # rubocop:enable Layout/SpaceInsideArrayLiteralBrackets, Layout/ExtraSpacing, Layout/LineLength
    end

    class ConditionMap
      def initialize
        @values = []
      end

      def register(value, condition)
        @values << { value: value, condition: condition }
      end

      def fetch(key)
        matched = @values.find { |value| value[:condition].call key }
        raise KeyError, "No matching value or key '#{key.inspect}'" unless matched

        matched[:value]
      end

      def values
        Enumerator.new do |y|
          @values.each do |v|
            y << v[:value]
          end
        end
      end
    end

    class TilesetLayout
      def initialize(tiles)
        @tiles = tiles

        @tile_positions = (0..255).map { |bitmask|
          position = tile_positions_by_condition.fetch Neighbors.new(bitmask)
          [bitmask, position]
        }.to_h
      end

      def tile_position_for(bitmask)
        @tile_positions[bitmask]
      end

      def tiles_with_xy
        Enumerator.new do |y|
          @tiles.reverse.each_with_index { |row, tile_y|
            row.each_with_index { |tile, tile_x|
              next unless tile

              y.yield(tile, tile_x, tile_y)
            }
          }
        end
      end

      private

      def tile_positions_by_condition
        @tile_positions_by_condition ||= ConditionMap.new.tap { |result|
          tiles_with_xy.each { |tile, tile_x, tile_y|
            condition = ->(n) { n.include?(tile[:value]) && n.exclude?(tile[:forbidden] || 255 - tile[:value]) }
            result.register [tile_x, tile_y].freeze, condition
          }
        }
      end
    end

    class TilesetBuilder
      def initialize(tilesource_path, size, layout)
        @tilesource_path = tilesource_path
        @size = size
        @layout = layout
        @tile_builder = TileBuilder.new(size)
      end

      def build_primitives
        @layout.tiles_with_xy.flat_map { |tile, tile_x, tile_y|
          tile_primitives(tile, tile_x * @size, tile_y * @size)
        }
      end

      private

      def tile_primitives(tile, offset_x, offset_y)
        @tile_builder.generate(tile[:value]).tap { |tile_parts|
          tile_parts.each do |part|
            part[:x] += offset_x
            part[:y] += offset_y
            part[:path] = @tilesource_path
          end
        }
      end
    end

    TILESET_47 = TilesetLayout.new Tiles::TILESET_47
    FULL_TILESET = TilesetLayout.new Tiles::FULL_TILESET
  end
end
