#encoding: utf-8
class GameWindow < Gosu::Window
  def initialize
    super(WIDTH, HEIGHT, FULLSCREEN)
    self.caption = "Fruit Killer v#{VERSION}"
    Dir.chdir File.join( File.dirname(__FILE__), "..", "media" )
    @profiles         = YAML.load_file(PROFILES_FILE) rescue []
    @guest_profile    = Profile.new("Guest")
    @games            = Dir['*/'].map { |d| d.sub('/', '') }
    @no_profiles      = @profiles.empty?

    @background_image = Image.new(self, File.join(MEDIA_PATH, "background2.png"), true)
    @main_menu        = Image.new(self, File.join(MEDIA_PATH, "main_menu.png"), true)
    @ok_button1       = Img.new(self, File.join(MEDIA_PATH, "ok_button.png"), width/2-57, 270, ZOrder::Menu)
    @ok_button2       = Img.new(self, File.join(MEDIA_PATH, "ok_button.png"), 520, 100, ZOrder::InputBox)
    @start_button     = Img.new(self, File.join(MEDIA_PATH, "start_button2.png"), width/2-100, 400, ZOrder::Menu)
    @apple_globe      = Img.new(self, File.join(MEDIA_PATH, "apple_globe.png"), WIDTH-375, HEIGHT-340, ZOrder::Element)
    @font             = Font.new(self, "American Typewriter", 96)
    @big_font         = Font.new(self, "American Typewriter", 128)
    @medium_font      = Font.new(self, "American Typewriter", 62)
    @score_font       = Font.new(self, "American Typewriter", 48)
    @small_font       = Font.new(self, "American Typewriter", 32)
    @font70           = Font.new(self, "American Typewriter", 70)
    @font79           = Font.new(self, "American Typewriter", 79)
    @game_menu        = Slide_Menu.new(self, 400, HEIGHT-100, ZOrder::MenuString, SOFT_GREEN, @games, @score_font, 480, @games.index("Fruits"))
    @profile_menu     = Slide_Menu.new(self, 400, 170, ZOrder::MenuString, YELLOW, @profiles, @medium_font, 480, 0, "name")
    @game_state       = :profile_menu
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
        @game = SingleGame.new(self, elements)
        @game_state = :running
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
    @main_menu.draw(0, 0, ZOrder::Background2)
    @game_menu.draw
  end

# ===========
# = VS Menu =
# ===========
  def button_down_vs_menu(id, x, y)
    if id == MsLeft
      tw1 = @medium_font.text_width("SPLITSCREEN")
      tw2 = @medium_font.text_width("NETWORK")
      if y > HEIGHT-100 and x < 200
        @game_state = :main_menu
      elsif x > (width-tw1)/2 and x < (width+tw1)/2 and y > 300 and y < 375
        all_profiles = @profiles + [@guest_profile]
        @p1_menu = Slide_Menu.new(self, width*0.25-200, 300, ZOrder::Menu, SOFT_ORANGE, all_profiles, @score_font, 400, all_profiles.index(@player), "name")
        @p2_menu = Slide_Menu.new(self, width*0.75-200, 300, ZOrder::Menu, SOFT_ORANGE, all_profiles, @score_font, 400, all_profiles.index(@guest_profile), "name")
        @game_state  = :splitscreen_menu
      elsif x > (width-tw2)/2 and x < (width+tw2)/2 and y > 375 and y < 450
        @game_state = :network_menu
      end
    end
  end

  def draw_vs_menu
    draw_centered(10, "VS MODE", @font, YELLOW, width, 0)
    draw_menu(300, ["SPLITSCREEN", "NETWORK"])
    @apple_globe.draw
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, 200, 0)
  end

# ====================
# = Splitscreen Menu =
# ====================
  def button_down_splitscreen_menu(id, x, y)
    if id == MsLeft
      if y > HEIGHT-100 and x < 200
        @game_state = :vs_menu
      elsif @start_button.mouse_inside?
        @p1 = @p1_menu.akt_element; @p2 = @p2_menu.akt_element
        puts "Player 1 chose profile #{@p1.name}; Player 2 chose profile #{@p2.name}"
        puts "Users chose game #{elements = @game_menu.akt_element}"
        @game = SplitscreenGame.new(self, elements)
        @game_state = :running
      else
        @game_menu.update; @p1_menu.update; @p2_menu.update
      end
    end
  end

  def draw_splitscreen_menu
    draw_centered(10, "SPLITSCREEN", @font, GREEN, width, 0)
    @medium_font.draw("Player 1:", width*0.25-@medium_font.text_width("Player 1:")/2, 200, ZOrder::MenuString, 1.0, 1.0, SOFT_ORANGE)
    @medium_font.draw("Player 2:", width*0.75-@medium_font.text_width("Player 2:")/2, 200, ZOrder::MenuString, 1.0, 1.0, SOFT_ORANGE)
    @game_menu.draw; @p1_menu.draw; @p2_menu.draw
    @start_button.draw
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, 200, 0)
  end

# ================
# = Network Menu =
# ================
  def button_down_network_menu(id, x, y)
    if id == MsLeft
      if y > HEIGHT-100 and x < 200
        @game_state = :vs_menu
      end
    end
  end

  def draw_network_menu
    draw_centered(10, "NETWORK", @font, GREEN, width, 0)
    draw_menu(300, ["Not implemented yet :("])
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, 200, 0)
  end

# ==============
# = Statistics =
# ==============
  def button_down_statistics(id, x, y)
      @game_state = :main_menu if y > HEIGHT-100 and x < 200 and id == MsLeft
  end

  def draw_statistics
    draw_centered(10, "STATISTICS", @font, YELLOW, width/2, -45)
    if @player != @guest_profile
      av_score = @player.score_sum/@player.games_played rescue 0
      text = ["PROFILE NAME: #{@player.name}",
              "GAMES PLAYED: #{@player.games_played}",
              "LAST PLAYED: #{@player.last_played.strftime("%d.%m.%y")}",
              "AVERAGE SCORE: #{av_score}",
              "LAST SCORE: #{@player.last_score}",
              "HIGH SCORES:"]
      @player.high_scores.each {|k, v| text << "   #{k}: #{v}"}
      text +=["MULTIPLAYER GAMES PLAYED: #{@player.vs_games_played}",
              "SPLITSCREEN GAMES WON/LOST: #{@player.ss_games_won}/#{@player.ss_games_lost}"]
    else
      text = ["There are no statistics for the Guest-Profile :("]
    end
    text.each_with_index {|t, i| @score_font.draw(t, 45, i*50+120, 1, 1.0, 1.0, YELLOW)}
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, 200, 0)
  end

# ================
# = Profile Menu =
# ================
  def button_down_profile_menu(id, x, y)
    if @no_profiles
      start_y = 200
    else
      @profile_menu.update
      if @ok_button1.mouse_inside? and id == MsLeft
        @player = @profile_menu.akt_element
        puts "User chose player #{@player.name}"
        @game_state = :main_menu
      end
      start_y = 475
      text_width = @medium_font.text_width("Delete profiles")
      if x > (width - text_width)/2 and x < (width + text_width)/2 and y > 625 and y < 700
        @game_state = :delete_profiles
        return nil
      end
    end
    text_width = @medium_font.text_width("Play as Guest")
    text_width2 = @medium_font.text_width("Create new profile")
    if x > (width - text_width)/2 and x < (width + text_width)/2 and y > (start_y+75) and y < (start_y + 150)
      @player = @guest_profile
      puts "User chose Guest Profile"
      @game_state = :main_menu
    elsif x > (width - text_width2)/2 and x < (width + text_width2)/2 and y > start_y
      @text_input = Input_Box.new(self, 52, 100, ZOrder::InputBox, ZOrder::InputBoxString, 450, 50, 43)
      @text_input.activate
      @message = "Please enter the name of the new profile:"
      @game_state = :create_profile
    end
  end

  def draw_profile_menu
    draw_centered(10, "Choose your profile", @font, YELLOW, width, 0)
    if @no_profiles
      draw_menu(200, ["Create new profile", "Play as Guest"])
    else
      @profile_menu.draw
      @ok_button1.draw
      draw_centered(360, "--------- OR ---------", @font79, YELLOW, width, 0)
      draw_menu(475, ["Create new profile", "Play as Guest", "Delete profiles"])
    end
  end

# ==================
# = Create Profile =
# ==================
  def button_down_create_profile(id, x, y)
    if (@ok_button2.mouse_inside? and id == MsLeft) or id == KbReturn
      name_included = false
      @profiles.each do |p|
        name_included = true if p.name == @text_input.text
      end
      name_included = true if @text_input.text.upcase == "GUEST" or @text_input.text == ""
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
        @no_profiles = false
        @profile_menu.update_options(@profiles, 0, "name")
        @game_state = :main_menu
      end
    elsif id == MsLeft and y > HEIGHT-100 and x < 200
      @game_state = :profile_menu
    end
  end

  def draw_create_profile
    @score_font.draw(@message, 50, 35, ZOrder::MenuString, 1.0, 1.0, YELLOW)
    @text_input.draw
    @ok_button2.draw
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, 200, 0)
  end

# ===================
# = Delete Profiles =
# ===================
  def button_down_delete_profiles(id, x, y)
    @profile_menu.update
    text_width = @score_font.text_width("Delete all profiles and highscores")
    if @ok_button1.mouse_inside? and id == MsLeft
      name = @profile_menu.akt_element.name
      @profiles.delete(@profile_menu.akt_element)
      save_profiles
      puts "Profile '#{name}' has been deleted."
      @no_profiles = @profiles.empty?
      @profile_menu.update_options(@profiles, 0, "name")
      @game_state = :profile_menu
    elsif x > (width - text_width)/2 and x < (width + text_width)/2 and y > 450 and y < 500 and id == MsLeft
      @profiles = []
      @no_profiles = true
      @profile_menu.update_options(@profiles, 0, "name")
      File.delete(PROFILES_FILE, SCORES_FILE)
      puts "THE PROFILES FILE AND THE SCORE FILE HAVE BEEN DELETED."
      @game_state = :profile_menu
    elsif id == MsLeft and y > HEIGHT-100 and x < 200
      @game_state = :profile_menu
    end
  end

  def draw_delete_profiles
    draw_centered(20, "Please choose the profile to delete:", @font70, YELLOW, width, 0)
    @profile_menu.draw
    @ok_button1.draw
    text = "Delete all profiles and highscores"
    @score_font.draw(text, (width - @score_font.text_width(text))/2, 450, ZOrder::MenuString, 1.0, 1.0, YELLOW)
    draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, 200, 0)
  end

# ==========
# = Won SP =
# ==========
  def button_down_won_sp(id, x, y)
    if id == MsLeft and y > HEIGHT-100
      if x < WIDTH/3
        @game_state = :main_menu
      elsif x < WIDTH*2/3
        @game = SingleGame.new(self, @game.elements)
        @game_state = :running
      else
        close
      end
    end
  end

  def draw_won_sp
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
    draw_won
    draw_scores
  end

# ===================
# = Won Splitscreen =
# ===================
  def button_down_won_splitscreen(id, x, y)
    if id == MsLeft and y > HEIGHT-100
      if x < WIDTH/3
        @game_state = :main_menu
      elsif x < WIDTH*2/3
        @game = SplitscreenGame.new(self, @game.elements)
        @game_state = :running
      else
        close
      end
    end
  end

  def draw_won_splitscreen
    range = (@winner == @p1)? [width/2, 0, width, width/2] : [width, width/2, width/2, 0]
    draw_centered(270, "WINNER", @big_font, GREEN, range[0], range[1])
    draw_centered(370, "#{@winner.name}", @big_font, WHITE, range[0], range[1])
    draw_centered(300, "LOOSER", @font79, RED, range[2], range[3])
    draw_centered(370, "#{@looser.name}", @font79, WHITE, range[2], range[3])
    draw_won
  end
# ===========
# = Routine =
# ===========
  def button_down(id)
    x = mouse_x; y = mouse_y
    if id == KbQ
      close
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
    if @game_state == :running
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
    if @player != @guest_profile
      @player.add_game(@game.score.to_i, @game.elements)
      save_profiles
    end
    @game_state = :won_sp
  end

  def game_won_splitscreen(winner)
    if winner == "p1"
      @winner = @p1; @looser = @p2
    else
      @winner = @p2; @looser = @p1
    end
    @winner.add_splitscreen_game(true) if @winner != @guest_profile
    @looser.add_splitscreen_game(false) if @winner != @guest_profile
    save_profiles
    @game_state = :won_splitscreen
  end

  protected
    def needs_cursor?
      true
    end

    def save_profiles
      File.open(PROFILES_FILE, "w") { |f| f.write YAML.dump(@profiles) }
    end

    def draw_centered(y, string, font = @font, color = YELLOW, right = width/2, left = 0, factor_x = 1.0, factor_y = 1.0)
      font_x = left + ( right - font.text_width(string)*factor_x - left ) / 2
      font.draw( string, font_x+8, y+8, 1, factor_x, factor_y, GRAY )
      font.draw( string, font_x, y, 1, factor_x, factor_y, color )
    end

    def draw_menu(start_y, items, method = nil)
      if method
        ary = items
        items = []
        ary.each{|e| items << e.send(method)}
      end
      items.each_with_index do |name, index|
				x = (width - @medium_font.text_width(name))/2
				y = start_y + index * 75
        @medium_font.draw(name, x, y, ZOrder::MenuString, 1.0, 1.0, YELLOW)
      end
    end

    def draw_won
      draw_centered(0, "#{@game.elements} – Game Over", @big_font, YELLOW, width)
      right = @medium_font.text_width("MAIN MENU") + 30
      draw_centered(HEIGHT-70, "MAIN MENU", @medium_font, ORANGE, right, 0)
      draw_centered(HEIGHT-70, "PLAY AGAIN", @medium_font, GREEN, width, 0)
      left = width - @medium_font.text_width("QUIT") - 30
      draw_centered(HEIGHT-70, "QUIT", @medium_font, RED, width, left)
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
end