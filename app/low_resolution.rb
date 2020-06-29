# require 'lib/low_resolution_canvas.rb'

class LowResolutionExample
  def tick(args)
    # Specify your canvas resolution as the first constructor argument
    args.state.canvas ||= LowResolutionCanvas.new([64, 64])

    args.state.canvas.background_color = [255, 255, 255]
    args.state.canvas.labels << [20, 60, 'test']
    args.state.canvas.primitives << [2, 2, 4, 4, 255, 0, 0].solid
    # Render your game content to your LowResolutionCanvas like you would to args.outputs

    args.outputs.background_color = [0, 0, 0]
    # Be sure to add your LowResolutionCanvas to args.outputs.primitives or args.outputs.sprites to render it to the screen
    args.outputs.primitives << args.state.canvas
  end
end
