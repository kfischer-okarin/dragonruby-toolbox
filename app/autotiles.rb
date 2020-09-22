# require 'lib/low_resolution_canvas.rb'

class AutotileExample
  def tick(args)
    args.state.initialized ||= { tileset: false }
    if !args.state.initialized[:tileset]
      args.render_target(:tileset).sprites << DRT::Autotile.generate_full_tileset('sprites/grass-autotile.png')
      args.state.initialized[:tileset] = true
    else
      args.outputs.sprites << {
        x: 0, y: 0, w: 512, h: 512, source_w: 512, source_h: 512, source_x: 0, source_y: 0, path: :tileset
      }
    end
  end
end
