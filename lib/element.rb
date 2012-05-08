#encoding: utf-8
class Element
  attr_accessor :x, :y, :name
  def initialize(owner, filename, x_range = [0, owner.width])
    @owner    = owner
    @name     = File.basename(filename).sub(".png", "")
    @image    = Gosu::Image.new(@owner, filename)
    @x        = rand(x_range[1] - x_range[0] - 64) + 32 + x_range[0]
    @y        = rand(@owner.height - 64) + 32
    @width    = @image.width
    @height   = @image.height
    @x_range  = x_range
    @target_x = @x + rand(100) - 50
    @target_y = @y + rand(100) - 50
  end

  def draw
    @image.draw(@x, @y, ZOrder::Element)
  end

  def update
    if Gosu::distance(@target_x, @target_y, @x, @y) < 4.0
      tries = 10
      begin
        @target_x = @x + rand(100) - 50
        @target_y = @y + rand(100) - 50
        tries -= 1
      end until inside?(@target_x, @target_y) || tries < 0
    else
      if @target_x - @x > 2
        @x += 1
      elsif @target_x - @x < -2
        @x -= 1
      end

      if @target_y - @y > 2
        @y += 1
      elsif @target_y - @y < -2
        @y -= 1
      end
    end
  end

  def inside?(x,y)
    x >= (@width/2 + @x_range[0])  &&
      x <= (@x_range[1] - @width/2) &&
      y >= @height/2 &&
      y <= HEIGHT - @height/2
  end
end
