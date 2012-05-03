class Game
  attr_reader :elements, :score
  def initialize(window, elements)
    @window     = window
    @elements   = elements
    @new_fruits = Dir.glob("#{elements}/*.png").sample(10).map { |filename| Element.new(@window, filename) }
    @fruits     = @new_fruits.dup
    @current    = @fruits.sample
    @score      = 0.0

    @hit_sound  = Gosu::Sample.new(@window, File.join(MEDIA_PATH, "squeeze_toy.mp3"))
    @miss_sound = Gosu::Sample.new(@window, File.join(MEDIA_PATH, "dinosaur.mp3"))
    @font       = Gosu::Font.new(@window, "American Typewriter", 96)
    @small_font = Gosu::Font.new(@window, "American Typewriter", 32)
  end

  def button_down(id, x, y)
    if id == Gosu::MsLeft
      if x >= WIDTH-10 && y >= HEIGHT-10
        close
      elsif Gosu.distance(x,y,@current.x,@current.y) < ELEMENT_WIDTH+8
        @hit_sound.play
        @score += 200
        @fruits.delete(@current)
        if @fruits.empty?
          @current = nil
          @window.game_won
        else
          @current = @fruits.sample
        end
      else
        @miss_sound.play
        @score = [0, @score-100].max
      end
    elsif id == Gosu::KbQ
      @window.close
    end
  end

  def update
    @fruits.each { |fruit| fruit.update }
    @score -= 0.5 if @score >= 1.0
  end

  def draw
    @fruits.each { |fruit| fruit.draw }
    font_x = ( @window.width - @font.text_width(@current.name) ) / 2
    font_y = 0
    @font.draw(@current.name, font_x, font_y, ZOrder::String, 1.0, 1.0, YELLOW)
    @font.draw(@score.to_i.to_s,  20, font_y, ZOrder::String, 1.0, 1.0, YELLOW)
    font_x = WIDTH - @small_font.text_width("Q")
    @small_font.draw("Q", font_x, HEIGHT-30, ZOrder::String, 1.0, 1.0, YELLOW)
  end
end