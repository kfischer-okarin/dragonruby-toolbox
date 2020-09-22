# Copyright (c) 2020 Kevin Fischer
# https://github.com/kfischer-okarin/dragonruby-toolbox
# Released under the MIT License (see repository)

module DRT
  module Autotile
    SYMBOLS = {
      up: 0b00000001, up_right: 0b00000010, right: 0b00000100, down_right: 0b00001000,
      down: 0b00010000, down_left: 0b00100000, left: 0b01000000, up_left: 0b10000000
    }.freeze
    VECTORS = {
      [0, 1] => 0b00000001, [1, 1] => 0b00000010, [1, 0] => 0b00000100, [1, -1] => 0b00001000,
      [0, -1] => 0b00010000, [-1, 1] => 0b00100000, [-1, 0] => 0b01000000, [-1, 1] => 0b10000000
    }.freeze

    def self.bitmask_for(value)
      return value if value.is_a? Fixnum

      if value.is_a?(Array)
        case value[0]
        when Array
          return value.map { |v| VECTORS[v] }.inject(0) { |sum, n| sum + n }
        when Symbol
          return value.map { |v| SYMBOLS[v] }.inject(0) { |sum, n| sum + n }
        end
      end

      raise "Value '#{value}' cannot be converted to bitmask"
    end

    class Condition
      def and(condition)
        Condition::And.new(self, condition)
      end

      def or(condition)
        Condition::Or.new(self, condition)
      end

      class Has < Condition
        def initialize(directions)
          @bitmask = Autotile.bitmask_for(directions)
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

    class << self
      def has(*directions)
        Condition::Has.new(directions)
      end

      def has_not(*directions)
        Condition::HasNot.new(directions)
      end
    end

    TILE_PARTS = {
      [0, 0] => {
        corner: :up_left,
        condition: has_not(:up, :left).and(has_not(:right).or(has_not(:down)))
      },
      [1, 0] => {
        corner: :up_right,
        condition: has_not(:up, :right).and(has_not(:left).or(has_not(:down)))
      },
      [2, 0] => {
        corner: :up_left,
        condition: has(:up, :left).and(has_not(:up_left))
      },
      [3, 0] => {
        corner: :up_right,
        condition: has(:up, :right).and(has_not(:up_right))
      },
      [0, 1] => {
        corner: :down_left,
        condition: has_not(:down, :left).and(has_not(:right).or(has_not(:up)))
      },
      [1, 1] => {
        corner: :down_right,
        condition: has_not(:down, :right).and(has_not(:left).or(has_not(:up)))
      },
      [2, 1] => {
        corner: :down_left,
        condition: has(:down, :left).and(has_not(:down_left))
      },
      [3, 1] => {
        corner: :down_right,
        condition: has(:down, :right).and(has_not(:down_right))
      },
      [0, 2] => {
        corner: :up_left,
        condition: has_not(:up, :left).and(has(:right, :down))
      },
      [1, 2] => {
        corner: :up_right,
        condition: has_not(:up).and(has(:right))
      },
      [2, 2] => {
        corner: :up_left,
        condition: has_not(:up).and(has(:left))
      },
      [3, 2] => {
        corner: :up_right,
        condition: has_not(:up, :right).and(has(:left, :down))
      },
      [0, 3] => {
        corner: :down_left,
        condition: has_not(:left).and(has(:down))
      },
      [1, 3] => {
        corner: :down_right,
        condition: has(:right, :down, :down_right)
      },
      [2, 3] => {
        corner: :down_left,
        condition: has(:left, :down, :down_left)
      },
      [3, 3] => {
        corner: :down_right,
        condition: has_not(:right).and(has(:down))
      },
      [0, 4] => {
        corner: :up_left,
        condition: has_not(:left).and(has(:up))
      },
      [1, 4] => {
        corner: :up_right,
        condition: has(:right, :up, :up_right)
      },
      [2, 4] => {
        corner: :up_left,
        condition: has(:left, :up, :up_left)
      },
      [3, 4] => {
        corner: :up_right,
        condition: has_not(:right).and(has(:up))
      },
      [0, 5] => {
        corner: :down_left,
        condition: has_not(:down, :left).and(has(:right, :up))
      },
      [1, 5] => {
        corner: :down_right,
        condition: has_not(:down).and(has(:right))
      },
      [2, 5] => {
        corner: :down_left,
        condition: has_not(:down).and(has(:left))
      },
      [3, 5] => {
        corner: :down_right,
        condition: has_not(:down, :right).and(has(:left, :up))
      }
    }

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
        TILE_PARTS.select { |tile_coord, definition|
          definition[:corner] == corner
        }.map { |tile_coord, definition|
          {
            condition: definition[:condition],
            sprite: {
              tile_x: @part_size * tile_coord.x,
              tile_y: @part_size * tile_coord.y,
              tile_w: @part_size,
              tile_h: @part_size,
            }
          }
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

    class TilesetBuilder
      def initialize(tile_size, tileset_definition)
        @tile_size = tile_size
        @tile_builder = TileBuilder.new(tile_size)
        @tileset_definition = tileset_definition
      end

      def build(source)
        @tileset_definition.flat_map.with_index { |row, tile_y|
          row.map.with_index { |value, tile_x|
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
  end
end
