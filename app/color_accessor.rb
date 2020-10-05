# require 'lib/color.rb'
# require 'lib/attr_sprite_accessor.rb'

# rubocop:disable all
class ColorAccessorExample
  def tick(args)
    args.state.dragon ||= create_dragon
    args.state.dragon.tick(args)

    handle_dragon_movement(args)

    args.outputs.labels << [10, 600, "Press 1, 2, 3 or 4 to change dragon color"]

    # attr_sprite enhances classes support a color setter method when lib/attr_sprite_color.rb is included
    args.state.dragon.color = Color.new(255, 255, 255) if args.inputs.keyboard.key_down.one
    args.state.dragon.color = Color.new(200, 200, 0) if args.inputs.keyboard.key_down.two
    args.state.dragon.color = Color.new(30, 100, 200) if args.inputs.keyboard.key_down.three
    args.state.dragon.color = Color.new(100, 200, 100) if args.inputs.keyboard.key_down.four

    args.outputs.sprites << args.state.dragon
  end

  def create_dragon
    frames = (1..6).map { |i| "sprites/dragon_fly#{i}.png" }

    AnimatedSprite.new(frames).tap { |result|
      result.x = 300
      result.y = 400
      result.w = 100
      result.h = 80
    }
  end

  def handle_dragon_movement(args)
    if args.inputs.keyboard.directional_vector
      args.state.dragon.x += args.inputs.keyboard.directional_vector.x * 10
      args.state.dragon.y += args.inputs.keyboard.directional_vector.y * 10
    end
  end

  class AnimatedSprite
    attr_sprite

    def initialize(frames, frame_duration = 5)
      @frames = frames
      @frame_duration = frame_duration
      @next_frame = 0
      @current_frame_index = -1
    end

    def tick(args)
      if args.tick_count >= @next_frame
        @current_frame_index = (@current_frame_index + 1) % @frames.size
        @next_frame = args.tick_count + @frame_duration
      end
    end

    def path
      @frames[@current_frame_index]
    end
  end
end
