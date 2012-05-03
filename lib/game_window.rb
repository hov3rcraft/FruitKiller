#encoding: utf-8
class GameWindow < Gosu::Window
  def initialize
    super(WIDTH, HEIGHT, false)
    self.caption = "Fruit Killer v#{VERSION}"
    Dir.chdir File.join( File.dirname(__FILE__), "..", "media" )
    @profiles   = YAML.load_file(PROFILES_FILE) rescue []
    @games      = Dir['*/'].map { |d| d.sub('/', '') }
    @profile_menu_options = @profiles.empty? ? [] : ["Choose existing profile"]
    @profile_menu_options << "Create new profile" << "Play as Guest"

    @background_image = Gosu::Image.new(self, File.join(MEDIA_PATH, "background2.png"), true)
    @main_menu  = Gosu::Image.new(self, File.join(MEDIA_PATH, "main_menu.png"), true)
    @font       = Gosu::Font.new(self, "American Typewriter", 96)
    @big_font   = Gosu::Font.new(self, "American Typewriter", 128)
    @medium_font= Gosu::Font.new(self, "American Typewriter", 62)
    @score_font = Gosu::Font.new(self, "American Typewriter", 48)
    @small_font = Gosu::Font.new(self, "American Typewriter", 32)
    @game_menu  = Slide_Menu.new(self, 400, HEIGHT-100, ZOrder::MenuString, SOFT_GREEN, @games, @score_font, 480, @games.index("Fruits"))
    @game_state = :profile_menu
  end

# =============
# = Main Menu =
# =============
  def button_down_main_menu(id, x, y)
    if id == MsLeft
      elements = @game_menu.update
      if x > 1065 and y > 245 and x < 1255 and y < 300
     	  puts "User chose game #{elements}"
        @scores = HighScores.new(elements)
        setup_game(elements)
      elsif x > 955 and y > 330 and x < 1255 and y < 385
        @game_state = :vs_menu
      elsif x > 935 and y > 420 and x < 1255 and y < 475
        @game_state = :statistics
      elsif x > 730 and y > 505 and x < 1255 and y < 560
        @game_state = :profile_menu
      elsif x > 1090 and y > 585 and x < 1255 and y < 640
        close
      end
    end
  end

  def draw_main_menu
    @main_menu.draw(0, 0, ZOrder::Menu)
    @game_menu.draw
  end

# ===========
# = VS Menu =
# ===========
  def button_down_vs_menu(id, x, y)
    if id == MsLeft
      if y > HEIGHT-100 and x < 200
        @game_state = :main_menu
      else
        elements = @game_menu.update
      end
    end
  end

  def draw_vs_menu
    draw_centered(10, "VS MODE", @font, GREEN, width, 0)
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, width/2, -200)
    @game_menu.draw
  end

# ==============
# = Statistics =
# ==============
  def button_down_statistics(id, x, y)
      @game_state = :main_menu if y > HEIGHT-100 and x < 200 and id == MsLeft
  end

  def draw_statistics
    draw_centered(10, "STATISTICS", @font, YELLOW, width/2, -45)
    #@font.draw("STATISTICS:", 45, 10, 1, 1.0, 1.0, YELLOW)
    av_score = @player.score_sum/@player.games_played rescue 0
    text = ["PROFILE NAME: #{@player.name}",
            "GAMES PLAYED: #{@player.games_played}",
            "LAST PLAYED: #{@player.last_played.strftime("%d.%m.%y")}",
            "AVERAGE SCORE: #{av_score}",
            "LAST SCORE: #{@player.last_score}",
            "HIGH SCORES:"]
    @player.high_scores.each {|k, v| text << "   #{k}: #{v}"}
    text.each_with_index {|t, i| @score_font.draw(t, 45, i*50+120, 1, 1.0, 1.0, YELLOW)}
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, width/2, -200)
  end

# ================
# = Profile Menu =
# ================
  def button_down_profile_menu(id, x, y)
    case find_name(@profile_menu_options, x, y)
    when "Choose existing profile"
      @game_state = :choose_profile
    when "Create new profile"
      @text_input = Input_Box.new(self, 12, 75, ZOrder::InputBox, ZOrder::InputBoxString, 450, 50, 43)
      @text_input.activate
      @ok_button = Img.new(self, "ok_button.png", 480, 75, ZOrder::InputBox)
      @message = "Please enter the name of the new profile:"
      @game_state = :create_profile
    when "Play as Guest"
      @player = Profile.new("Guest")
      puts "User chose Guest Profile"
      @game_state = :main_menu
    end
  end

  def draw_profile_menu
    draw_menu(@profile_menu_options)
  end

# ==================
# = Create Profile =
# ==================
  def button_down_create_profile(id, x, y)
    if (@ok_button.mouse_inside? and id == MsLeft) or id == KbReturn
      name_included = false
      @profiles.each do |p|
        name_included = true if p.name == @text_input.text
      end
      name_included = true if @text_input.text == "Guest"
      if name_included
        @message = "'#{@text_input.text}' ist not available. Please try again."
        @text_input.text = ""
      elsif @big_font.text_width(@text_input.text) > 640
        @message = "'#{@text_input.text}' is too long. Please try again."
      else
        @player = Profile.new(@text_input.text)
        @profiles << @player
        save_profiles
        puts "Profile '#{@player.name}' was created"
        @text_input.deactivate
        @game_state = :main_menu
      end
    elsif id == MsLeft and y > HEIGHT-100
      @game_state = :profile_menu
    end
  end

  def draw_create_profile
    @score_font.draw(@message, 10, 10, 1, 1.0, 1.0, YELLOW)
    @text_input.draw
    @ok_button.draw
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, width/2, -200)
  end

# =======
# = Won =
# =======
  def button_down_won(id, x, y)
    if y > HEIGHT-100
      if x < WIDTH/3
        @game_state = :main_menu
      elsif x < WIDTH*2/3
        setup_game(@game.elements)
      else
        close
      end
    end
  end

  def draw_won
    draw_centered(0, "#{@game.elements} – Game Over", @big_font, YELLOW, width)

    factor_x = 588.0/@big_font.text_width(@player.name.upcase)
    factor_x = 1.0 if factor_x > 1.0
    draw_centered(270, @player.name.upcase, @big_font, WHITE, @scores ? width/2 : width, 0, factor_x)
    draw_centered(370, "#{@game.score.to_i} points", @big_font, YELLOW, @scores ? width/2 : width)

    if @scores
      if @place
        message = "Congratulations, you made #{(@place+1).ord_string} place!"
      else
        message = "Sorry, you didn’t make it into the high score table..."
      end
      draw_centered(HEIGHT-150, message, @score_font, WHITE, width)
    end

    draw_centered(HEIGHT-70, "MAIN MENU", @medium_font, ORANGE, width/2, -150)
    draw_centered(HEIGHT-70, "PLAY AGAIN", @medium_font, GREEN, width/2, width/4)
    draw_centered(HEIGHT-70, "QUIT", @medium_font, RED, width/2, 875)

    draw_scores
  end

# ===========
# = Routine =
# ===========
  def button_down(id)
    x = mouse_x; y = mouse_y
    if id == Gosu::KbQ
      close
    elsif @game_state == :choose_profile and @player = find_name(@profiles, x, y)
			puts "User chose player #{@player.name}"
      @game_state = :main_menu
    elsif @game_state == :running
      @game.button_down(id, x, y)
    else
      send("button_down_" + @game_state.to_s, id, x, y)
    end
  end

  def update
    @game.update if @game_state == :running
  end

  def draw
    @background_image.draw(0, 0, ZOrder::Background)
    if @game_state == :choose_profile
      draw_menu(@profiles, "name")
    elsif @game_state == :running
      @game.draw
    else
      send("draw_" + @game_state.to_s)
    end
  end

# ====================
# = Weitere Methoden =
# ====================
  def game_won
    @place = @scores.new_score Score.new(@game.score.to_i, @player.name, Date.today) if @scores
    if @player.name != "Guest"
      @player.add_game(@game.score.to_i, @game.elements)
      save_profiles
    end
    @game_state = :won
  end

  protected
    def needs_cursor?
      true
    end

    def save_profiles
      File.open(PROFILES_FILE, "w") { |f| f.write YAML.dump(@profiles) }
    end

    def setup_game(game)
      @game = Game.new(self, game)
      @game_state = :running
    end

    def draw_centered(y, string, font = @font, color = YELLOW, right = width/2, left = 0, factor_x = 1.0, factor_y = 1.0)
      font_x = left + ( right - font.text_width(string)*factor_x ) / 2
      font.draw( string, font_x+8, y+8, 1, factor_x, factor_y, GRAY )
      font.draw( string, font_x, y, 1, factor_x, factor_y, color )
    end

    def draw_menu(items, method = nil)
      if method
        ary = items
        items = []
        ary.each{|e| items << e.send(method)}
      end
      items.each_with_index do |name, index|
				x = 100 + (index / 12) * (WIDTH/3)
				y = (index % 12) * 58
        @font.draw(name, x, y, ZOrder::MenuString, 1.0, 1.0, 0xffffff00)
      end
    end

    def draw_scores
      # draw_line WIDTH/2, 0, WHITE, WIDTH/2, height, WHITE # middle line
			x0 = WIDTH/2 + 16
			x1 = x0 +  96
			x2 = x1 + 232 + @score_font.text_width("9999")
			x3 = x2 + 32
      @scores.each_with_index do |score, index|
				y = (index % 11) * 48 + 150
				color = @place == index ? YELLOW : WHITE
				x2s = x2 - @score_font.text_width(score.points)
        z = ZOrder::String
        @score_font.draw( (index+1).ord_string,            x0+4,  y+4, z, 1.0, 1.0, GRAY)
        @score_font.draw( score.name,                      x1+4,  y+4, z, 1.0, 1.0, GRAY)
        @score_font.draw( score.points,                    x2s+4, y+4, z, 1.0, 1.0, GRAY)
        @score_font.draw( score.date.strftime("%d.%m.%y"), x3+4,  y+4, z, 1.0, 1.0, GRAY)
        @score_font.draw( (index+1).ord_string,            x0,  y, z, 1.0, 1.0, color)
        @score_font.draw( score.name,                      x1,  y, z, 1.0, 1.0, color)
        @score_font.draw( score.points,                    x2s, y, z, 1.0, 1.0, color)
        @score_font.draw( score.date.strftime("%d.%m.%y"), x3,  y, z, 1.0, 1.0, color)
      end
    end

  	def find_name(items, x, y)
  		spalte = ((x - 100.0) / WIDTH * 3).to_i
  		zeile  = ((y -  20.0) / 58.0).to_i
      # puts "#{x}/#{y} => #{spalte}/#{zeile}"
  		index  = spalte * 12 + zeile
  		items[index]
  	end
end