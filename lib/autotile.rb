# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  module Autotile
    def self.generate_tileset_primitives(options)
      TILESET_47.generate_primitives(options[:path], options[:size])
    end

    def self.generate_full_tileset_primitives(options)
      FULL_TILESET.generate_primitives(options[:path], options[:size])
    end

    class Neighbors
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

      def +(direction)
        other_bitmask = Bitmask.from(direction)
        Neighbors.new(@bitmask | other_bitmask)
      end

      def -(direction)
        other_bitmask = Bitmask.from(direction)
        Neighbors.new(@bitmask & (255 - other_bitmask))
      end

      def include?(*directions)
        other_bitmask = Bitmask.from(*directions)
        @bitmask & other_bitmask == other_bitmask
      end

      def exclude?(*directions)
        other_bitmask = Bitmask.from(*directions)
        @bitmask & other_bitmask == 0
      end

      def serialize
        directions = SYMBOLS.keys.select { |d| include? d }
        "Neighbors.new(#{directions.to_s[1..-2]})"
      end

      def inspect
        serialize
      end
    end

    # Map from direction name to bitmask
    SYMBOLS = {
      up: 0b00000001, up_right: 0b00000010, right: 0b00000100, down_right: 0b00001000,
      down: 0b00010000, down_left: 0b00100000, left: 0b01000000, up_left: 0b10000000
    }.freeze
    # Map from vector to bitmask
    VECTORS = {
      [0, 1] => 0b00000001, [1, 1] => 0b00000010, [1, 0] => 0b00000100, [1, -1] => 0b00001000,
      [0, -1] => 0b00010000, [-1, -1] => 0b00100000, [-1, 0] => 0b01000000, [-1, 1] => 0b10000000
    }.freeze

    module Bitmask
      def self.from(*values)
        case values[0]
        when Fixnum
          values[0]
        when Array
          values.map { |v| VECTORS[v] }.inject(0) { |sum, n| sum + n }
        when Symbol
          values.map { |v| SYMBOLS[v] }.inject(0) { |sum, n| sum + n }
        when nil
          0
        else
          raise "Value '#{values}' cannot be converted to bitmask"
        end
      end
    end

    # Definition of tile parts that will make up the tiles in the end
    module TileParts
      SINGLE_UP_LEFT = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:up, :left) && (n.exclude?(:right) || n.exclude?(:down)) }
      }
      SINGLE_UP_RIGHT = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:up, :right) && (n.exclude?(:left) || n.exclude?(:down)) }
      }
      PLUS_UP_LEFT = {
        tile_corner: :up_left,
        condition: ->(n) { n.include?(:up, :left) && n.exclude?(:up_left) }
      }
      PLUS_UP_RIGHT = {
        tile_corner: :up_right,
        condition: ->(n) { n.include?(:up, :right) && n.exclude?(:up_right) }
      }
      SINGLE_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:down, :left) && (n.exclude?(:right) || n.exclude?(:up)) }
      }
      SINGLE_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:down, :right) && (n.exclude?(:left) || n.exclude?(:up)) }
      }
      PLUS_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: ->(n) { n.include?(:down, :left) && n.exclude?(:down_left) }
      }
      PLUS_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: ->(n) { n.include?(:down, :right) && n.exclude?(:down_right) }
      }
      CORNER_UP_LEFT = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:up, :left) && n.include?(:right, :down) }
      }
      UP_LEFT = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:up) && n.include?(:right) }
      }
      UP_RIGHT = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:up) && n.include?(:left) }
      }
      CORNER_UP_RIGHT = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:up, :right) && n.include?(:left, :down) }
      }
      LEFT_UP = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:left) && n.include?(:down) }
      }
      CENTER_UP_LEFT = {
        tile_corner: :down_right,
        condition: ->(n) { n.include?(:right, :down, :down_right) }
      }
      CENTER_UP_RIGHT = {
        tile_corner: :down_left,
        condition: ->(n) { n.include?(:left, :down, :down_left) }
      }
      RIGHT_UP = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:right) && n.include?(:down) }
      }
      LEFT_DOWN = {
        tile_corner: :up_left,
        condition: ->(n) { n.exclude?(:left) && n.include?(:up) }
      }
      CENTER_DOWN_LEFT = {
        tile_corner: :up_right,
        condition: ->(n) { n.include?(:right, :up, :up_right) }
      }
      CENTER_DOWN_RIGHT = {
        tile_corner: :up_left,
        condition: ->(n) { n.include?(:left, :up, :up_left) }
      }
      RIGHT_DOWN = {
        tile_corner: :up_right,
        condition: ->(n) { n.exclude?(:right) && n.include?(:up) }
      }
      CORNER_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:down, :left) && n.include?(:right, :up) }
      }
      DOWN_LEFT = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:down) && n.include?(:right) }
      }
      DOWN_RIGHT = {
        tile_corner: :down_left,
        condition: ->(n) { n.exclude?(:down) && n.include?(:left) }
      }
      CORNER_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: ->(n) { n.exclude?(:down, :right) && n.include?(:left, :up) }
      }

      PARTS = [
        [  SINGLE_UP_LEFT,   SINGLE_UP_RIGHT,      PLUS_UP_LEFT,     PLUS_UP_RIGHT],
        [SINGLE_DOWN_LEFT, SINGLE_DOWN_RIGHT,    PLUS_DOWN_LEFT,   PLUS_DOWN_RIGHT],
        [  CORNER_UP_LEFT,           UP_LEFT,          UP_RIGHT,   CORNER_UP_RIGHT],
        [         LEFT_UP,    CENTER_UP_LEFT,   CENTER_UP_RIGHT,          RIGHT_UP],
        [       LEFT_DOWN,  CENTER_DOWN_LEFT, CENTER_DOWN_RIGHT,        RIGHT_DOWN],
        [CORNER_DOWN_LEFT,         DOWN_LEFT,        DOWN_RIGHT, CORNER_DOWN_RIGHT]
      ]

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

    module Tiles
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

      TILESET_47 = [
        [  CORNER_UP_LEFT_TWO_LINES,         SIDE_UP,   CORNER_UP_RIGHT_TWO_LINES,               L_DOWN_RIGHT,            T_DOWN_LEFT_RIGHT,                L_DOWN_LEFT,        VERTICAL_LINE_END_UP],
        [                 SIDE_LEFT,          CENTER,                  SIDE_RIGHT,            T_UP_DOWN_RIGHT,                         PLUS,             T_UP_DOWN_LEFT,               VERTICAL_LINE],
        [CORNER_DOWN_LEFT_TWO_LINES,       SIDE_DOWN, CORNER_DOWN_RIGHT_TWO_LINES,                 L_UP_RIGHT,              T_UP_LEFT_RIGHT,                  L_UP_LEFT,      VERTICAL_LINE_END_DOWN],
        [            CORNER_UP_LEFT,    SIDE_UP_LINE,             CORNER_UP_RIGHT,   CORNER_UP_LEFT_LINE_LEFT,      CORNER_UP_RIGHT_LINE_UP,     CORNER_UP_LEFT_LINE_UP,  CORNER_UP_RIGHT_LINE_RIGHT],
        [            SIDE_LEFT_LINE,             nil,             SIDE_RIGHT_LINE, CORNER_DOWN_LEFT_LINE_DOWN, CORNER_DOWN_RIGHT_LINE_RIGHT, CORNER_DOWN_LEFT_LINE_LEFT, CORNER_DOWN_RIGHT_LINE_DOWN],
        [          CORNER_DOWN_LEFT,  SIDE_DOWN_LINE,           CORNER_DOWN_RIGHT,           FAT_PLUS_UP_LEFT,            FAT_PLUS_UP_RIGHT,      DIAGONAL_CONNECT_LEFT,      DIAGONAL_CONNECT_RIGHT],
        [  HORIZONTAL_LINE_END_LEFT, HORIZONTAL_LINE,   HORIZONTAL_LINE_END_RIGHT,         FAT_PLUS_DOWN_LEFT,          FAT_PLUS_DOWN_RIGHT,                        nil,                NO_NEIGHBORS]
      ].map(&:freeze).freeze
    end

    class TilesetDefinition
      def initialize(tiles)
        @tiles = tiles

        @tile_positions = (0..255).map { |bitmask|
          tile = tiles_with_condition.find { |tile| tile[:condition].call Neighbors.new(bitmask) }
          [bitmask, tile[:position]]
        }.to_h
      end

      def tile_position_for(bitmask)
        @tile_positions[bitmask]
      end

      def generate_primitives(tile_source_path, tile_size)
        tile_builder = TileBuilder.new(tile_size)

        @tiles.reverse.flat_map.with_index { |row, tile_y|
          row.map.with_index { |tile, tile_x|
            next unless tile

            x = tile_x * tile_size
            y = tile_y * tile_size
            tile_builder.generate(tile[:value]).tap { |tile_parts|
              tile_parts.each do |part|
                part[:x] += x
                part[:y] += y
                part[:path] = tile_source_path
              end
            }
          }
        }
      end

      private

      def tiles_with_condition
        @tiles_with_condition ||= @tiles.reverse.flat_map.with_index { |row, y|
          row.map.with_index { |tile, x|
            next nil unless tile

            {
              position: [x, y].freeze,
              condition: ->(n) { n.include?(tile[:value]) && n.exclude?(tile[:forbidden] || 255 - tile[:value]) }
            }
          }
        }.compact
      end
    end

    TILESET_47 = TilesetDefinition.new Tiles::TILESET_47
    FULL_TILESET = TilesetDefinition.new Tiles::FULL_TILESET

    class Tile
      def initialize(path, size, tileset = nil)
        @path = path
        @size = size
        @sprites = calc_sprites(tileset || TILESET_47)
      end

      def render(neighbors)
        @sprites[neighbors]
      end

      private

      def calc_sprites(tileset)
        tiles = {}
        (0..255).map { |bitmask|
          tile_position = tileset.tile_position_for(bitmask)
          tiles[tile_position] ||= {
            path: @path,
            w: @size,
            h: @size,
            source_x: tile_position.x * @size,
            source_y: tile_position.y * @size,
            source_w: @size,
            source_h: @size
          }.freeze
          [Neighbors.new(bitmask), tiles[tile_position]]
        }.to_h
      end
    end
  end
end
