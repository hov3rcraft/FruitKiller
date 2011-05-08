class Element
  attr_accessor :x, :y, :name
  def initialize(owner, filename)
    @owner    = owner
    @name     = File.basename(filename).sub(".png", "")
    @image    = Gosu::Image.new(@owner, filename)
    @x        = rand(@owner.width - 64) + 32
    @y        = rand(@owner.height - 64) + 32
    @target_x = @x + rand(100) - 50
    @target_y = @y + rand(100) - 50
  end

  def draw
    @image.draw(@x, @y, 0)
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
    x >= ELEMENT_WIDTH/2 &&
      x <= WIDTH - ELEMENT_WIDTH/2 &&
      y >= ELEMENT_WIDTH/2 &&
      y <= HEIGHT - ELEMENT_WIDTH/2
  end
end
