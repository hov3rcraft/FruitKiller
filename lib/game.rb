class Game
  attr_reader :elements, :score
  def initialize(window, elements)
    @window      = window
    @elements    = elements
    @new_fruits  = Dir.glob("#{elements}/*.png").sample(10)
    @fruits      = @new_fruits.map { |filename| Element.new(@window, filename) }
    @current     = 0
    @score       = 0.0

    @hit_sound   = Gosu::Sample.new(@window, File.join(MEDIA_PATH, "squeeze_toy.mp3"))
    @miss_sound  = Gosu::Sample.new(@window, File.join(MEDIA_PATH, "dinosaur.mp3"))
    @font        = Gosu::Font.new(@window, "American Typewriter", 96)
    @medium_font = Font.new(@window, "American Typewriter", 62)
    @small_font  = Gosu::Font.new(@window, "American Typewriter", 32)
  end

  def button_down(id, x, y)
    if id == Gosu::MsLeft and x >= WIDTH-30 && y >= HEIGHT-30
      close
    elsif id == Gosu::KbQ
      @window.close
    end
  end

  def update
    @fruits.each { |fruit| fruit.update }
    @score -= 0.5 if @score >= 1.0
  end

  def draw
    @fruits[@current..-1].each { |fruit| fruit.draw }
    item_x = ( @window.width - @font.text_width(@fruits[@current].name) ) / 2
    @font.draw(@fruits[@current].name, item_x, 0, ZOrder::String, 1.0, 1.0, YELLOW)
    @font.draw(@score.to_i.to_s, 20, 0, ZOrder::String, 1.0, 1.0, YELLOW)
    @small_font.draw("Q", WIDTH - @small_font.text_width("Q"), HEIGHT-30, ZOrder::String, 1.0, 1.0, YELLOW)
  end
end

class SingleGame < Game
  def button_down(id, x, y)
    super
    if id == MsLeft
      if Gosu.distance(x,y,@fruits[@current].x,@fruits[@current].y) < 64 + 8
        @hit_sound.play
        @score += 200
        if @current >= (@fruits.size - 1)
          @window.game_won
        else
          @current += 1
        end
      else
        @miss_sound.play
        @score = [0, @score-100].max
      end
    end
  end
end

class SplitscreenGame < Game
  def initialize(window, elements)
    super
    @background = Img.new(window, "background.png", 0, 0, ZOrder::Background2)
    @fruits     = @new_fruits.map { |filename| Element.new(@window, filename, [0, WIDTH/2]) }
    @fruits2    = @new_fruits.map { |filename| Element.new(@window, filename, [WIDTH/2, WIDTH]) }
    @all_fruits = @fruits + @fruits2
    @current2 = 0
  end

  def button_down(id, x, y)
    super
    if id == MsLeft
      if Gosu.distance(x, y, @fruits[@current].x, @fruits[@current].y) < 64 + 8
        @hit_sound.play
        if @current >= (@fruits.size - 1)
          @window.game_won_splitscreen("p1")
        else
          @current += 1
        end
      elsif Gosu.distance(x, y, @fruits2[@current2].x, @fruits2[@current2].y) < 64 + 8
        @hit_sound.play
        if @current2 >= (@fruits2.size - 1)
          @window.game_won_splitscreen("p2")
        else
          @current2 += 1
        end
      else
       @miss_sound.play
      end
    end
  end

  def update
    @all_fruits.each { |fruit| fruit.update }
  end

  def draw
    @background.draw
    (@fruits[@current..-1] + @fruits2[@current2..-1]).each { |fruit| fruit.draw}
    @medium_font.draw(@fruits[@current].name, 20, 0, ZOrder::String, 1.0, 1.0, YELLOW)
    x = WIDTH - @medium_font.text_width(@fruits2[@current2].name) - 20
    @medium_font.draw(@fruits2[@current2].name, x, 0, ZOrder::String, 1.0, 1.0, YELLOW)
    x = WIDTH/2 - @medium_font.text_width(10-@current) - 7
    @medium_font.draw(10-@current, x, 0, ZOrder::String, 1.0, 1.0, YELLOW)
    @medium_font.draw(10-@current2, WIDTH/2+7, 0, ZOrder::String, 1.0, 1.0, YELLOW)
    @small_font.draw("Q", WIDTH - @small_font.text_width("Q"), HEIGHT-30, ZOrder::String, 1.0, 1.0, YELLOW)
  end
end