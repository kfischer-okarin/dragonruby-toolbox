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
          @bitmask = Autotile.bitmask(*directions)
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

      CORNER_UP_LEFT = bitmask(:right, :down_right, :down)
      CORNER_UP_RIGHT = bitmask(:left, :down_left, :down)
      CORNER_DOWN_LEFT = bitmask(:right, :up_right, :up)
      CORNER_DOWN_RIGHT = bitmask(:left, :up_left, :up)

      SIDE_UP = bitmask(:left, :down_left, :down, :down_right, :right)
      SIDE_DOWN = bitmask(:left, :up_left, :up, :up_right, :right)
      SIDE_LEFT = bitmask(:up, :up_right, :right, :down_right, :down)
      SIDE_RIGHT = bitmask(:up, :up_left, :left, :down_left, :down)

      CENTER = bitmask(:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left)

      CORNER_UP_LEFT_LINE_LEFT = bitmask(:left, :down, :down_right, :right)
      CORNER_UP_LEFT_LINE_UP = bitmask(:up, :down, :down_right, :right)
      CORNER_UP_RIGHT_LINE_UP = bitmask(:up, :left, :down_left, :down)
      CORNER_UP_RIGHT_LINE_RIGHT = bitmask(:right, :left, :down_left, :down)
      CORNER_DOWN_LEFT_LINE_DOWN = bitmask(:down, :right, :up_right, :up)
      CORNER_DOWN_LEFT_LINE_LEFT = bitmask(:left, :right, :up_right, :up)
      CORNER_DOWN_RIGHT_LINE_RIGHT = bitmask(:right, :up, :up_left, :left)
      CORNER_DOWN_RIGHT_LINE_DOWN = bitmask(:down, :up, :up_left, :left)

      CORNER_UP_LEFT_TWO_LINES = bitmask(:left, :up, :right, :down_right, :down)
      CORNER_UP_RIGHT_TWO_LINES = bitmask(:right, :up, :left, :down_left, :down)
      CORNER_DOWN_LEFT_TWO_LINES = bitmask(:left, :down, :right, :up_right, :up)
      CORNER_DOWN_RIGHT_TWO_LINES = bitmask(:right, :down, :left, :up_left, :up)

      SIDE_UP_LINE = bitmask(:left, :up, :right, :down_right, :down, :down_left)
      SIDE_LEFT_LINE = bitmask(:up, :left, :down, :down_right, :right, :up_right)
      SIDE_RIGHT_LINE = bitmask(:up, :right, :down, :down_left, :left, :up_left)
      SIDE_DOWN_LINE = bitmask(:left, :down, :right, :up_right, :up, :up_left)

      L_DOWN_RIGHT = bitmask(:right, :down)
      L_DOWN_LEFT = bitmask(:left, :down)
      L_UP_RIGHT = bitmask(:right, :up)
      L_UP_LEFT = bitmask(:left, :up)

      T_DOWN_LEFT_RIGHT = bitmask(:left, :down, :right)
      T_UP_DOWN_RIGHT = bitmask(:right, :up, :down)
      T_UP_DOWN_LEFT = bitmask(:left, :up, :down)
      T_UP_LEFT_RIGHT = bitmask(:left, :up, :right)

      PLUS = bitmask(:left, :right, :up, :down)

      FAT_PLUS_UP_LEFT = bitmask(:left, :up, :up_right, :right, :down_right, :down, :down_left)
      FAT_PLUS_UP_RIGHT = bitmask(:right, :up, :up_left, :left, :down_left, :down, :down_right)
      FAT_PLUS_DOWN_LEFT = bitmask(:left, :down, :down_right, :right, :up_right, :up, :up_left)
      FAT_PLUS_DOWN_RIGHT = bitmask(:right, :down, :down_left, :left, :up_left, :up, :up_right)

      DIAGONAL_CONNECT_RIGHT = bitmask(:up, :up_right, :right, :down, :down_left, :left)
      DIAGONAL_CONNECT_LEFT = bitmask(:up, :up_left, :left, :down, :down_right, :right)

      VERTICAL_LINE_END_UP = bitmask(:down)
      VERTICAL_LINE = bitmask(:up, :down)
      VERTICAL_LINE_END_DOWN = bitmask(:up)

      HORIZONTAL_LINE_END_LEFT = bitmask(:right)
      HORIZONTAL_LINE = bitmask(:left, :right)
      HORIZONTAL_LINE_END_RIGHT = bitmask(:left)

      NO_NEIGHBORS = 0

      TILESET_47 = [
        [  CORNER_UP_LEFT_TWO_LINES,         SIDE_UP,   CORNER_UP_RIGHT_TWO_LINES,               L_DOWN_RIGHT,            T_DOWN_LEFT_RIGHT,                L_DOWN_LEFT,        VERTICAL_LINE_END_UP],
        [                 SIDE_LEFT,          CENTER,                  SIDE_RIGHT,            T_UP_DOWN_RIGHT,                         PLUS,             T_UP_DOWN_LEFT,               VERTICAL_LINE],
        [CORNER_DOWN_LEFT_TWO_LINES,       SIDE_DOWN, CORNER_DOWN_RIGHT_TWO_LINES,                 L_UP_RIGHT,              T_UP_LEFT_RIGHT,                  L_UP_LEFT,      VERTICAL_LINE_END_DOWN],
        [            CORNER_UP_LEFT,    SIDE_UP_LINE,             CORNER_UP_RIGHT,   CORNER_UP_LEFT_LINE_LEFT,      CORNER_UP_RIGHT_LINE_UP,     CORNER_UP_LEFT_LINE_UP,  CORNER_UP_RIGHT_LINE_RIGHT],
        [            SIDE_LEFT_LINE,             nil,             SIDE_RIGHT_LINE, CORNER_DOWN_LEFT_LINE_DOWN, CORNER_DOWN_RIGHT_LINE_RIGHT, CORNER_DOWN_LEFT_LINE_LEFT, CORNER_DOWN_RIGHT_LINE_DOWN],
        [          CORNER_DOWN_LEFT,  SIDE_DOWN_LINE,           CORNER_DOWN_RIGHT,           FAT_PLUS_UP_LEFT,            FAT_PLUS_UP_RIGHT,      DIAGONAL_CONNECT_LEFT,      DIAGONAL_CONNECT_RIGHT],
        [  HORIZONTAL_LINE_END_LEFT, HORIZONTAL_LINE,   HORIZONTAL_LINE_END_RIGHT,         FAT_PLUS_DOWN_LEFT,          FAT_PLUS_DOWN_RIGHT,                        nil,                NO_NEIGHBORS]
      ]

      FULL_TILESET = (0...16).map { |row|
        start = row * 16
        (start...(start + 16)).to_a
      }
    end

    class TilesetBuilder
      def initialize(tile_size, tileset_definition)
        @tile_size = tile_size
        @tile_builder = TileBuilder.new(tile_size)
        @tileset_definition = tileset_definition
      end

      def build(source)
        @tileset_definition.reverse.flat_map.with_index { |row, tile_y|
          row.map.with_index { |value, tile_x|
            next unless value

            x = tile_x * @tile_size
            y = tile_y * @tile_size
            @tile_builder.generate(value).tap { |tile_parts|
              tile_parts.each do |part|
                part[:x] += x
                part[:y] += y
                part[:path] = source
              end
            }
          }
        }
      end
    end

    def self.generate_full_tileset(autotile_source)
      TilesetBuilder.new(32, Tiles::FULL_TILESET).build(autotile_source)
    end

    def self.generate_tileset_47(autotile_source)
      TilesetBuilder.new(32, Tiles::TILESET_47).build(autotile_source)
    end
  end
end
