#!/Users/mk/.rvm/bin/ruby-1.9.2-p180@gosu
# encoding: utf-8

VERSION = "1.4"
DATE    = "2011-05-08"

require 'gosu'
require 'yaml'
require_relative 'gosu_mod'
require_relative 'element'
include Gosu

WIDTH            = 1280
HEIGHT           = 800
ELEMENT_WIDTH    = 64

WHITE            = 0xFFFFFFFF
BLACK            = 0xFF000000
YELLOW           = 0XFFFFFF00
GREEN            = 0XFF00FF00
SOFT_GREEN       = 0XFF66FF66
RED              = 0XFFFF0000
ORANGE           = 0XFFFF7700
GRAY             = 0X77444444

PREFERENCES_PATH = File.dirname(__FILE__)
PROFILES_FILE    = File.join(PREFERENCES_PATH, 'profiles.yml')
SCORES_FILE      = File.join(PREFERENCES_PATH, 'scores.yml')

Score = Struct.new(:points, :name, :date) do
end

class Fixnum
  def ord_string
    case self
    when 1
      "1st"
    when 2  
      "2nd"
    when 3
      "3rd"
    else
      "#{self}th"
    end
  end
end

class HighScores
  def initialize(game)
    @game   = game
    @scores = YAML.load_file(SCORES_FILE) rescue {}
  end
  
  def new_score(score)
    (@scores[@game] ||= []) << score
    @scores[@game] = @scores[@game].sort_by { |s| -s.points }.first(10)
    File.open(SCORES_FILE, "w") { |f| f.write YAML.dump(@scores) }
    @scores[@game].index(score)
  end
  
  def [](index)
    @scores[@game][index]
  end
  
  def each_with_index(&block)
    @scores[@game].each_with_index(&block)
  end
end

class Profile
  attr_reader :name, :games_played, :score_sum, :last_score, :high_scores, :last_played
  def initialize(name)
    @name = name
    @games_played = 0
    @score_sum    = 0
    @last_score   = 0
    @high_scores  = {}
    @last_played  = Date.today
  end

  def add_game(score, game, all_profiles)
    @games_played     += 1
    @score_sum        += score
    @last_score        = score
    if @high_scores[game]
      @high_scores[game] = score if score > @high_scores[game]
    else
      @high_scores[game] = score
    end
    @last_played       = Date.today
    File.open(PROFILES_FILE, "w") { |f| f.write YAML.dump(all_profiles) }
  end
end

# ==============
# = GameWindow =
# ==============
class GameWindow < Gosu::Window
  def initialize
    super(WIDTH, HEIGHT, false)
    self.caption = "Fruit Killer v.#{VERSION}"
    Dir.chdir File.join( File.dirname(__FILE__), "media" )
    @profiles   = YAML.load_file(PROFILES_FILE) rescue []
    @games      = Dir['*/'].map { |d| d.sub('/', '') }
    @profile_menu_options = @profiles.empty? ? [] : ["Choose existing profile"]
    @profile_menu_options << "Create new profile" << "Play as Guest"

    @background_image = Gosu::Image.new(self, "background2.png", true)
    @main_menu  = Gosu::Image.new(self, "main_menu.png", true)
    @hit_sound  = Gosu::Sample.new(self, "squeeze_toy.mp3")
    @miss_sound = Gosu::Sample.new(self, "dinosaur.mp3")
    @font       = Gosu::Font.new(self, "American Typewriter", 96)
    @big_font   = Gosu::Font.new(self, "American Typewriter", 128)
    @medium_font= Gosu::Font.new(self, "American Typewriter", 62)
    @score_font = Gosu::Font.new(self, "American Typewriter", 48)
    @small_font = Gosu::Font.new(self, "American Typewriter", 32)
    @game_menu  = Slide_Menu.new(self, 400, HEIGHT-100, 2, SOFT_GREEN, @games, @score_font, 480, @games.index("Fruits"))
    @game_state = :profile_menu

    # @game       = "Superfruits"
    # @score      = 9999
    # @game_state = :won # for debugging
  end

  def setup_game
    @fruits     = @new_fruits.dup
    @current    = @fruits.sample
    @score      = 0.0
    @game_state = :running
  end

  def needs_cursor?
    true
  end

  def button_down(id)
    x = mouse_x; y = mouse_y
    if id == Gosu::KbQ
      close
    elsif @game_state == :profile_menu
      case find_name(@profile_menu_options, x, y)
      when "Choose existing profile"
        @game_state = :choose_profile
      when "Create new profile"
        @text_input = Input_Box.new(self, 12, 75, 450, 50, 43)
        @text_input.activate
        @ok_button = Img.new(self, "ok_button.png", 480, 75, 1)
        @message = "Please enter the name of the new profile:"
        @game_state = :create_profile
      when "Play as Guest"
        @player = Profile.new("Guest")
        puts "User chose Guest Profile"
        @game_state = :main_menu
      end
    elsif @game_state == :main_menu
      if id == MsLeft
        @game = @game_menu.update
        if x > 1070 and y > 290 and x < 1255 and y < 340
         	puts "User chose game #{@game}"
          @scores     = HighScores.new(@game)
          @new_fruits = Dir.glob("#{@game}/*.png").sample(10).map { |filename| Element.new(self, filename) }
          setup_game
        elsif x > 940 and y > 385 and x < 1255 and y < 435
          @game_state = :statistics
        elsif x > 740 and y > 480 and x < 1255 and y < 530
          @game_state = :profile_menu
        elsif x > 1090 and y > 575 and x < 1255 and y < 630
          close
        end
      end
    elsif @game_state == :choose_profile and @player = find_name(@profiles, x, y)
			puts "User chose player #{@player.name}"
      @game_state = :main_menu
    elsif @game_state == :create_profile
      if (@ok_button.mouse_inside? and id == MsLeft) or id == KbReturn
        name_included = false
        @profiles.each do |p|
          name_included = true if p.name == @text_input.text
        end
        name_included = true if @text_input.text == "Guest"
        if name_included
          @message = "'#{@text_input.text}' ist not available. Please try again."
          @text_input.text = ""
        else
          @player = Profile.new(@text_input.text)
          @profiles << @player
          File.open(PROFILES_FILE, "w") { |f| f.write YAML.dump(@profiles) }
          puts "Profile '#{@player.name}' was created"
          @text_input.deactivate
          @game_state = :main_menu
        end
      elsif id == MsLeft and y > HEIGHT-100
        @game_state = :profile_menu
      end
    elsif @game_state == :statistics and y > HEIGHT-100 and id == MsLeft
      @game_state = :main_menu
    elsif @game_state == :running
      if id == Gosu::MsLeft
        if x >= WIDTH-10 && y >= HEIGHT-10
          close
        elsif Gosu.distance(x,y,@current.x,@current.y) < ELEMENT_WIDTH+8
          @hit_sound.play
          @score += 200
          @fruits.delete(@current)
          if @fruits.empty?
            game_won
          else
            @current = @fruits.sample
          end
        else
          @miss_sound.play
          @score = [0, @score-100].max
        end
      elsif id == Gosu::KbQ
        close
      end
    elsif @game_state == :won
      if y > HEIGHT-100
        if x < WIDTH/3
          @game_state = :main_menu
        elsif x < WIDTH*2/3
          setup_game
        else
          close
        end
      end
    end
  end

  def update
    if @game_state == :running
      @fruits.each { |fruit| fruit.update }
      @score -= 0.5 if @score >= 1.0
    end
  end

  def draw
    @background_image.draw(0, 0, -1)
    if @game_state == :profile_menu
      draw_menu(@profile_menu_options)
    elsif @game_state == :main_menu
      @main_menu.draw(0, 0, 0)
      @game_menu.draw
    elsif @game_state == :statistics
      @font.draw("STATISTICS:", 10, 10, 1, 1.0, 1.0, YELLOW)
      av_score = @player.score_sum/@player.games_played rescue 0
      text = ["GAMES PLAYED: #{@player.games_played}",
              "LAST PLAYED: #{@player.last_played.strftime("%d.%m.%y")}",
              "AVERAGE SCORE: #{av_score}",
              "LAST SCORE: #{@player.last_score}",
              "HIGH SCORES:"]
      @player.high_scores.each {|k, v| text << "   #{k}: #{v}"}
      text.each_with_index {|t, i| @score_font.draw(t, 10, i*50+120, 1, 1.0, 1.0, YELLOW)}
      draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, width/2, -200)
    elsif @game_state == :choose_profile
      draw_menu(@profiles, "name")
    elsif @game_state == :create_profile
      @score_font.draw(@message, 10, 10, 1, 1.0, 1.0, YELLOW)
      @text_input.draw
      @ok_button.draw
      draw_centered(HEIGHT-70, "BACK", @medium_font, ORANGE, width/2, -200)
    elsif @game_state == :running
      @fruits.each { |fruit| fruit.draw }
      font_x = ( width - @font.text_width(@current.name) ) / 2
      font_y = 0
      @font.draw(@current.name, font_x, font_y, 1, 1.0, 1.0, YELLOW)
      @font.draw(@score.to_i.to_s,  20, font_y, 1, 1.0, 1.0, YELLOW)
      font_x = WIDTH - @small_font.text_width("Q")
      @small_font.draw("Q", font_x, HEIGHT-30, 1, 1.0, 1.0, YELLOW)
    elsif @game_state == :won
      draw_centered(0, "#{@game} – Game Over", @big_font, YELLOW, width)

      factor_x = 588.0/@big_font.text_width(@player.name.upcase)
      factor_x = 1.0 if factor_x > 1.0
      draw_centered(270, @player.name.upcase, @big_font, WHITE, @scores ? width/2 : width, 0, factor_x)
      draw_centered(370, "#{@score} points", @big_font, YELLOW, @scores ? width/2 : width)

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
  end

  protected
    def game_won
      @current    = nil
      @score      = @score.to_i
      @place      = @scores.new_score Score.new(@score, @player.name, Date.today) if @scores
      @player.add_game(@score, @game, @profiles) if @player.name != "Guest"
      @game_state = :won
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
        @font.draw(name, x, y, 1, 1.0, 1.0, 0xffffff00)
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
        @score_font.draw( (index+1).ord_string,            x0+4,  y+4, 1, 1.0, 1.0, GRAY)
        @score_font.draw( score.name,                      x1+4,  y+4, 1, 1.0, 1.0, GRAY)
        @score_font.draw( score.points,                    x2s+4, y+4, 1, 1.0, 1.0, GRAY)
        @score_font.draw( score.date.strftime("%d.%m.%y"), x3+4,  y+4, 1, 1.0, 1.0, GRAY)
        @score_font.draw( (index+1).ord_string,            x0,  y, 1, 1.0, 1.0, color)
        @score_font.draw( score.name,                      x1,  y, 1, 1.0, 1.0, color)
        @score_font.draw( score.points,                    x2s, y, 1, 1.0, 1.0, color)
        @score_font.draw( score.date.strftime("%d.%m.%y"), x3,  y, 1, 1.0, 1.0, color)
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

window = GameWindow.new
window.show
