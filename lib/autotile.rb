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

    def self.bitmask(*values)
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

    # ============ Bitmask Conditions start ============
    class Condition
      def and(condition)
        Condition::And.new(self, condition)
      end

      def or(condition)
        Condition::Or.new(self, condition)
      end

      class Has < Condition
        def initialize(directions)
          @bitmask = Autotile.bitmask(*directions)
        end

        def matches?(value)
          @bitmask & value == @bitmask
        end
      end

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
    end

    module ConditionHelpers
      def has(*directions)
        Condition::Has.new(directions)
      end

      def has_not(*directions)
        Condition::HasNot.new(directions)
      end
    end

    # ============ Bitmask Conditions end ============

    # Definition of tile parts that will make up the tiles in the end
    module TileParts
      extend ConditionHelpers

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
    end

    class TileBuilder
      def initialize(tile_size)
        @part_size = tile_size.idiv 2
        @up_left = definitions_for(:up_left)
        @up_right = definitions_for(:up_right)
        @down_left = definitions_for(:down_left)
        @down_right = definitions_for(:down_right)
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

      def definitions_for(corner)
        [].tap { |result|
          TileParts::PARTS.each.with_index do |row, y|
            row.each.with_index do |definition, x|
              next unless definition[:tile_corner] == corner

              result << {
                condition: definition[:condition],
                sprite: {
                  tile_x: @part_size * x,
                  tile_y: @part_size * y,
                  tile_w: @part_size,
                  tile_h: @part_size,
                }
              }
            end
          end
        }
      end

      def matching_part(definitions, value)
        matched = definitions.find { |definition| definition[:condition].matches? value }
        matched[:sprite]
      end
    end

    FULL_TILESET = (0...16).map { |row|
      start = row * 16
      (start...(start + 16)).to_a
    }.reverse

    TILESET_47 = [
      [
        # 3x3 filled top row
        bitmask(:left, :up, :right, :down_right, :down),
        bitmask(:left, :down_left, :down, :down_right, :right),
        bitmask(:right, :up, :left, :down_left, :down),
        # 3x3 grid top row
        bitmask(:right, :down),
        bitmask(:left, :down, :right),
        bitmask(:left, :down),
        # vertical line top
        bitmask(:down)
      ],
      [
        # 3x3 filled middle row
        bitmask(:up, :up_right, :right, :down_right, :down),
        bitmask(:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left),
        bitmask(:up, :up_left, :left, :down_left, :down),
        # 3x3 grid middle row
        bitmask(:right, :up, :down),
        bitmask(:left, :right, :up, :down),
        bitmask(:left, :up, :down),
        #vertical line middle
        bitmask(:up, :down)
      ],
      [
        # 3x3 filled bottom row
        bitmask(:left, :down, :right, :up_right, :up),
        bitmask(:left, :up_left, :up, :up_right, :right),
        bitmask(:right, :down, :left, :up_left, :up),
        # 3x3 grid bottom row
        bitmask(:right, :up),
        bitmask(:left, :up, :right),
        bitmask(:left, :up),
        # vertical line bottm
        bitmask(:up)
      ],
      [
        # 3x3 block with thin lines extruding - top
        bitmask(:right, :down_right, :down),
        bitmask(:left, :up, :right, :down_right, :down, :down_left),
        bitmask(:left, :down_left, :down),
        # 2x2 Shuriken A - top
        bitmask(:left, :down, :down_right, :right),
        bitmask(:up, :left, :down_left, :down),
        # 2x2 Shuriken B - top
        bitmask(:up, :down, :down_right, :right),
        bitmask(:right, :left, :down_left, :down)

      ],
      [
        # 3x3 block with thin lines extruding - middle
        bitmask(:up, :left, :down, :down_right, :right, :up_right),
        nil,
        bitmask(:up, :right, :down, :down_left, :left, :up_left),
        # 2x2 Shuriken A - bottom
        bitmask(:down, :right, :up_right, :up),
        bitmask(:right, :up, :up_left, :left),
        # 2x2 Shuriken B - bottom
        bitmask(:left, :right, :up_right, :up),
        bitmask(:down, :up, :up_left, :left)
      ],
      [
        # 3x3 block with thin lines extruding - top
        bitmask(:right, :up_right, :up),
        bitmask(:left, :down, :right, :up_right, :up, :up_left),
        bitmask(:left, :up_left, :up),
        # Fat Plus - top
        bitmask(:left, :up, :up_right, :right, :down_right, :down, :down_left),
        bitmask(:right, :up, :up_left, :left, :down_left, :down, :down_right),
        # Diagonal gaps
        bitmask(:up, :up_right, :right, :down, :down_left, :left),
        bitmask(:up, :up_left, :left, :down, :down_right, :right)
      ],
      [
        # horizontal line
        bitmask(:right),
        bitmask(:left, :right),
        bitmask(:left),
        # Fat Plus - bottom
        bitmask(:left, :down, :down_right, :right, :up_right, :up, :up_left),
        bitmask(:right, :down, :down_left, :left, :up_left, :up, :up_right),
        nil,
        # Single element
        0
      ]
    ].reverse

    class TilesetBuilder
      def initialize(tile_size, tileset_definition)
        @tile_size = tile_size
        @tile_builder = TileBuilder.new(tile_size)
        @tileset_definition = tileset_definition
      end

      def build(source)
        @tileset_definition.flat_map.with_index { |row, tile_y|
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
      TilesetBuilder.new(32, FULL_TILESET).build(autotile_source)
    end

    def self.generate_tileset_47(autotile_source)
      TilesetBuilder.new(32, TILESET_47).build(autotile_source)
    end
  end
end
