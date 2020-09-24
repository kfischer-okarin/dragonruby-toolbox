# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  module Autotile
    # Map from direction name to bitmask
    SYMBOLS = {
      up: 0b00000001, up_right: 0b00000010, right: 0b00000100, down_right: 0b00001000,
      down: 0b00010000, down_left: 0b00100000, left: 0b01000000, up_left: 0b10000000
    }.freeze
    # Map from vector to bitmask
    VECTORS = {
      [0, 1] => 0b00000001, [1, 1] => 0b00000010, [1, 0] => 0b00000100, [1, -1] => 0b00001000,
      [0, -1] => 0b00010000, [-1, 1] => 0b00100000, [-1, 0] => 0b01000000, [-1, 1] => 0b10000000
    }.freeze

    module BitmaskHelper
      def bitmask(*values)
        case values[0]
        when Fixnum
          values[0]
        when Array
          values.map { |v| VECTORS[v] }.inject(0) { |sum, n| sum + n }
        when Symbol
          values.map { |v| SYMBOLS[v] }.inject(0) { |sum, n| sum + n }
        else
          raise "Value '#{values}' cannot be converted to bitmask"
        end
      end
    end

    extend BitmaskHelper

    # Bitmask conditions
    class Condition
      def and(condition)
        Condition::And.new(self, condition)
      end

      def or(condition)
        Condition::Or.new(self, condition)
      end

      # Bitmask has all specified direction bits set
      class Has < Condition
        def initialize(directions)
          @bitmask = directions.is_a?(Fixnum) ? directions : Autotile.bitmask(*directions)
        end

        def matches?(value)
          @bitmask & value == @bitmask
        end
      end

      # Bitmask has none of the specified direction bits set
      class HasNot < Has
        def matches?(value)
          @bitmask & value == 0
        end
      end

      class And < Condition
        def initialize(*conditions)
          @conditions = conditions
        end

        def matches?(value)
          @conditions.all? { |c| c.matches? value }
        end
      end

      class Or < And
        def matches?(value)
          @conditions.any? { |c| c.matches? value }
        end
      end

      module Helpers
        def has(*directions)
          Has.new(directions)
        end

        def has_not(*directions)
          HasNot.new(directions)
        end
      end
    end

    # Definition of tile parts that will make up the tiles in the end
    module TileParts
      extend Condition::Helpers

      SINGLE_UP_LEFT = {
        tile_corner: :up_left,
        condition: has_not(:up, :left).and(has_not(:right).or(has_not(:down)))
      }
      SINGLE_UP_RIGHT = {
        tile_corner: :up_right,
        condition: has_not(:up, :right).and(has_not(:left).or(has_not(:down)))
      }
      PLUS_UP_LEFT = {
        tile_corner: :up_left,
        condition: has(:up, :left).and(has_not(:up_left))
      }
      PLUS_UP_RIGHT = {
        tile_corner: :up_right,
        condition: has(:up, :right).and(has_not(:up_right))
      }
      SINGLE_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: has_not(:down, :left).and(has_not(:right).or(has_not(:up)))
      }
      SINGLE_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: has_not(:down, :right).and(has_not(:left).or(has_not(:up)))
      }
      PLUS_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: has(:down, :left).and(has_not(:down_left))
      }
      PLUS_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: has(:down, :right).and(has_not(:down_right))
      }
      CORNER_UP_LEFT = {
        tile_corner: :up_left,
        condition: has_not(:up, :left).and(has(:right, :down))
      }
      UP_LEFT = {
        tile_corner: :up_right,
        condition: has_not(:up).and(has(:right))
      }
      UP_RIGHT = {
        tile_corner: :up_left,
        condition: has_not(:up).and(has(:left))
      }
      CORNER_UP_RIGHT = {
        tile_corner: :up_right,
        condition: has_not(:up, :right).and(has(:left, :down))
      }
      LEFT_UP = {
        tile_corner: :down_left,
        condition: has_not(:left).and(has(:down))
      }
      CENTER_UP_LEFT = {
        tile_corner: :down_right,
        condition: has(:right, :down, :down_right)
      }
      CENTER_UP_RIGHT = {
        tile_corner: :down_left,
        condition: has(:left, :down, :down_left)
      }
      RIGHT_UP = {
        tile_corner: :down_right,
        condition: has_not(:right).and(has(:down))
      }
      LEFT_DOWN = {
        tile_corner: :up_left,
        condition: has_not(:left).and(has(:up))
      }
      CENTER_DOWN_LEFT = {
        tile_corner: :up_right,
        condition: has(:right, :up, :up_right)
      }
      CENTER_DOWN_RIGHT = {
        tile_corner: :up_left,
        condition: has(:left, :up, :up_left)
      }
      RIGHT_DOWN = {
        tile_corner: :up_right,
        condition: has_not(:right).and(has(:up))
      }
      CORNER_DOWN_LEFT = {
        tile_corner: :down_left,
        condition: has_not(:down, :left).and(has(:right, :up))
      }
      DOWN_LEFT = {
        tile_corner: :down_right,
        condition: has_not(:down).and(has(:right))
      }
      DOWN_RIGHT = {
        tile_corner: :down_left,
        condition: has_not(:down).and(has(:left))
      }
      CORNER_DOWN_RIGHT = {
        tile_corner: :down_right,
        condition: has_not(:down, :right).and(has(:left, :up))
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
        base = { w: @part_size, h: @part_size }
        [
          base.merge(x: 0, y: 0).merge(matching_part(@down_left, value)),
          base.merge(x: @part_size, y: 0).merge(matching_part(@down_right, value)),
          base.merge(x: 0, y: @part_size).merge(matching_part(@up_left, value)),
          base.merge(x: @part_size, y: @part_size).merge(matching_part(@up_right, value))
        ]
      end

      private

      def matching_part(definitions, value)
        matched = definitions.find { |definition| definition[:condition].matches? value }
        matched[:sprite]
      end
    end

    module Tiles
      extend BitmaskHelper

      CORNER_UP_LEFT = {
        value: bitmask(:right, :down_right, :down),
        forbidden: bitmask(:up, :left)
      }
      CORNER_UP_RIGHT = {
        value: bitmask(:left, :down_left, :down),
        forbidden: bitmask(:up, :right)
      }
      CORNER_DOWN_LEFT = {
        value: bitmask(:right, :up_right, :up),
        forbidden: bitmask(:down, :left)
      }
      CORNER_DOWN_RIGHT = {
        value: bitmask(:left, :up_left, :up),
        forbidden: bitmask(:down, :right)
      }

      SIDE_UP = {
        value: bitmask(:left, :down_left, :down, :down_right, :right),
        forbidden: bitmask(:up)
      }
      SIDE_DOWN = {
        value: bitmask(:left, :up_left, :up, :up_right, :right),
        forbidden: bitmask(:down)
      }
      SIDE_LEFT = {
        value: bitmask(:up, :up_right, :right, :down_right, :down),
        forbidden: bitmask(:left)
      }
      SIDE_RIGHT = {
        value: bitmask(:up, :up_left, :left, :down_left, :down),
        forbidden: bitmask(:right)
      }

      CENTER = {
        value: bitmask(:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left)
      }

      CORNER_UP_LEFT_LINE_LEFT = {
        value: bitmask(:left, :down, :down_right, :right),
        forbidden: bitmask(:down_left, :up)
      }
      CORNER_UP_LEFT_LINE_UP = {
        value: bitmask(:up, :down, :down_right, :right),
        forbidden: bitmask(:up_right, :left)
      }
      CORNER_UP_RIGHT_LINE_UP = {
        value: bitmask(:up, :left, :down_left, :down),
        forbidden: bitmask(:up_left, :right)
      }
      CORNER_UP_RIGHT_LINE_RIGHT = {
        value: bitmask(:right, :left, :down_left, :down),
        forbidden: bitmask(:down_right, :up)
      }
      CORNER_DOWN_LEFT_LINE_DOWN = {
        value: bitmask(:down, :right, :up_right, :up),
        forbidden: bitmask(:down_right, :left)
      }
      CORNER_DOWN_LEFT_LINE_LEFT = {
        value: bitmask(:left, :right, :up_right, :up),
        forbidden: bitmask(:up_left, :down)
      }
      CORNER_DOWN_RIGHT_LINE_RIGHT = {
        value: bitmask(:right, :up, :up_left, :left),
        forbidden: bitmask(:up_right, :down)
      }
      CORNER_DOWN_RIGHT_LINE_DOWN = {
        value: bitmask(:down, :up, :up_left, :left),
        forbidden: bitmask(:down_left, :right)
      }

      CORNER_UP_LEFT_TWO_LINES = {
        value: bitmask(:left, :up, :right, :down_right, :down)
      }
      CORNER_UP_RIGHT_TWO_LINES = {
        value: bitmask(:right, :up, :left, :down_left, :down)
      }
      CORNER_DOWN_LEFT_TWO_LINES = {
        value: bitmask(:left, :down, :right, :up_right, :up)
      }
      CORNER_DOWN_RIGHT_TWO_LINES = {
        value: bitmask(:right, :down, :left, :up_left, :up)
      }

      SIDE_UP_LINE = {
        value: bitmask(:left, :up, :right, :down_right, :down, :down_left)
      }
      SIDE_LEFT_LINE = {
        value: bitmask(:up, :left, :down, :down_right, :right, :up_right)
      }
      SIDE_RIGHT_LINE = {
        value: bitmask(:up, :right, :down, :down_left, :left, :up_left)
      }
      SIDE_DOWN_LINE = {
        value: bitmask(:left, :down, :right, :up_right, :up, :up_left)
      }

      L_DOWN_RIGHT = {
        value: bitmask(:right, :down),
        forbidden: bitmask(:left, :up, :down_right)
      }
      L_DOWN_LEFT = {
        value: bitmask(:left, :down),
        forbidden: bitmask(:up, :right, :down_left)
      }
      L_UP_RIGHT = {
        value: bitmask(:right, :up),
        forbidden: bitmask(:left, :down, :up_right)
      }
      L_UP_LEFT = {
        value: bitmask(:left, :up),
        forbidden: bitmask(:right, :down, :up_left)
      }

      T_DOWN_LEFT_RIGHT = {
        value: bitmask(:left, :down, :right),
        forbidden: bitmask(:up, :down_left, :down_right)
      }
      T_UP_DOWN_RIGHT = {
        value: bitmask(:right, :up, :down),
        forbidden: bitmask(:left, :up_right, :down_right)
      }
      T_UP_DOWN_LEFT = {
        value: bitmask(:left, :up, :down),
        forbidden: bitmask(:right, :up_left, :down_left)
      }
      T_UP_LEFT_RIGHT = {
        value: bitmask(:left, :up, :right),
        forbidden: bitmask(:down, :up_left, :up_right)
      }

      PLUS = {
        value: bitmask(:left, :right, :up, :down)
      }

      FAT_PLUS_UP_LEFT = {
        value: bitmask(:left, :up, :up_right, :right, :down_right, :down, :down_left)
      }
      FAT_PLUS_UP_RIGHT = {
        value: bitmask(:right, :up, :up_left, :left, :down_left, :down, :down_right)
      }
      FAT_PLUS_DOWN_LEFT = {
        value: bitmask(:left, :down, :down_right, :right, :up_right, :up, :up_left)
      }
      FAT_PLUS_DOWN_RIGHT = {
        value: bitmask(:right, :down, :down_left, :left, :up_left, :up, :up_right)
      }

      DIAGONAL_CONNECT_RIGHT = {
        value: bitmask(:up, :up_right, :right, :down, :down_left, :left)
      }
      DIAGONAL_CONNECT_LEFT = {
        value: bitmask(:up, :up_left, :left, :down, :down_right, :right)
      }

      VERTICAL_LINE_END_UP = {
        value: bitmask(:down),
        forbidden: bitmask(:up, :left, :right)
      }
      VERTICAL_LINE = {
        value: bitmask(:up, :down),
        forbidden: bitmask(:left, :right)
      }
      VERTICAL_LINE_END_DOWN = {
        value: bitmask(:up),
        forbidden: bitmask(:left, :down, :right)
      }

      HORIZONTAL_LINE_END_LEFT = {
        value: bitmask(:right),
        forbidden: bitmask(:up, :left, :down)
      }
      HORIZONTAL_LINE = {
        value: bitmask(:left, :right),
        forbidden: bitmask(:up, :down)
      }
      HORIZONTAL_LINE_END_RIGHT = {
        value: bitmask(:left),
        forbidden: bitmask(:up, :right, :down)
      }

      NO_NEIGHBORS = {
        value: 0,
        forbidden: bitmask(:up, :down, :right, :left)
      }

      FULL_TILESET = (0...16).map { |row|
        start = row * 16
        (start...(start + 16)).map { |value|
          { value: value }
        }
      }

      TILESET_47 = [
        [  CORNER_UP_LEFT_TWO_LINES,         SIDE_UP,   CORNER_UP_RIGHT_TWO_LINES,               L_DOWN_RIGHT,            T_DOWN_LEFT_RIGHT,                L_DOWN_LEFT,        VERTICAL_LINE_END_UP],
        [                 SIDE_LEFT,          CENTER,                  SIDE_RIGHT,            T_UP_DOWN_RIGHT,                         PLUS,             T_UP_DOWN_LEFT,               VERTICAL_LINE],
        [CORNER_DOWN_LEFT_TWO_LINES,       SIDE_DOWN, CORNER_DOWN_RIGHT_TWO_LINES,                 L_UP_RIGHT,              T_UP_LEFT_RIGHT,                  L_UP_LEFT,      VERTICAL_LINE_END_DOWN],
        [            CORNER_UP_LEFT,    SIDE_UP_LINE,             CORNER_UP_RIGHT,   CORNER_UP_LEFT_LINE_LEFT,      CORNER_UP_RIGHT_LINE_UP,     CORNER_UP_LEFT_LINE_UP,  CORNER_UP_RIGHT_LINE_RIGHT],
        [            SIDE_LEFT_LINE,             nil,             SIDE_RIGHT_LINE, CORNER_DOWN_LEFT_LINE_DOWN, CORNER_DOWN_RIGHT_LINE_RIGHT, CORNER_DOWN_LEFT_LINE_LEFT, CORNER_DOWN_RIGHT_LINE_DOWN],
        [          CORNER_DOWN_LEFT,  SIDE_DOWN_LINE,           CORNER_DOWN_RIGHT,           FAT_PLUS_UP_LEFT,            FAT_PLUS_UP_RIGHT,      DIAGONAL_CONNECT_LEFT,      DIAGONAL_CONNECT_RIGHT],
        [  HORIZONTAL_LINE_END_LEFT, HORIZONTAL_LINE,   HORIZONTAL_LINE_END_RIGHT,         FAT_PLUS_DOWN_LEFT,          FAT_PLUS_DOWN_RIGHT,                        nil,                NO_NEIGHBORS]
      ]
    end

    # Source for generating Autotile tileset
    TileSource = Struct.new(:path, :size)

    class Tileset
      def initialize(tiles)
        @tiles = tiles
      end

      def build_from(tile_source)
        tile_builder = TileBuilder.new(tile_source.size)

        @tiles.reverse.flat_map.with_index { |row, tile_y|
          row.map.with_index { |tile, tile_x|
            next unless tile

            x = tile_x * tile_source.size
            y = tile_y * tile_source.size
            tile_builder.generate(tile[:value]).tap { |tile_parts|
              tile_parts.each do |part|
                part[:x] += x
                part[:y] += y
                part[:path] = tile_source.path
              end
            }
          }
        }
      end
    end

    TILESET_47 = Tileset.new Tiles::TILESET_47
    FULL_TILESET = Tileset.new Tiles::FULL_TILESET

    def self.generate_full_tileset(tile_source)
      FULL_TILESET.build_from(tile_source)
    end

    def self.generate_tileset_47(tile_source)
      TILESET_47.build_from(tile_source)
    end
  end
end
