# rubocop:disable all
require 'lib/transformations.rb'
require 'app/transformations.rb'

require 'lib/color.rb'
require 'app/colors_hsv_hsl.rb'

require 'lib/attr_sprite_color.rb'
require 'app/color_accessor.rb'

require 'lib/low_resolution_canvas.rb'
require 'app/low_resolution.rb'

require 'lib/autotile.rb'
require 'app/autotiles.rb'

require 'app/damage_numbers.rb'

def tick(args)
  if $current_example
    $current_example.tick(args)

    $current_example = nil if args.inputs.keyboard.key_down.escape
  else
    setup_examples if args.tick_count.zero?
    render_menu(args)
  end
end

def setup_examples
  $examples = [
    { name: 'Transformations', example: TransformationsExample.new },
    { name: 'Colors (HSV / HSL)', example: ColorsHsvHslExample.new },
    { name: 'Colors (Accessor for attr_sprite)', example: ColorAccessorExample.new },
    { name: 'Low Resolution Canvas', example: LowResolutionExample.new },
    { name: 'Autotiles', example: AutotileExample.new },
    { name: 'Damage Numbers', example: DamageNumbersExample.new }
  ]
end

BUTTONS = ('a'..'z').to_a

def render_menu(args)
  args.outputs.labels << { x: 400, y: 650, text: "Examples", size_enum: 2 }

  y = 600
  $examples.each.with_index do |example, i|
    button = BUTTONS[i]
    args.outputs.labels << [400, y, "#{button}) #{example[:name]}"]

    if args.inputs.keyboard.key_down.send("#{button}!") # Use ! method to consume key event
      $current_example = example[:example]
      $gtk.reset
    end

    y -= 24
  end

  args.outputs.labels << [10, 30, 'Press Escape inside an example to return to the menu']
end
