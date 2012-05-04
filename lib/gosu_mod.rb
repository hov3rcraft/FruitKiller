#encoding: utf-8

# Eine Sammlung nützlicher Klassen, die das Programmieren mit Gosu vereinfachen soll.
#
# Erstellt von Christian Hovestadt
# Version vom 4.5.2012

class Background
  def initialize(window, path)
    @window = window
    @y1 = 0
    @y2 = -HEIGHT
    @img = Image.new(@window, path, true)
  end

  def move_y(speed)
    @y1 += speed; @y2 += speed
    if @y1 >= HEIGHT
      @y1 = @y2
      @y2 = -HEIGHT
    end
  end

  def img_change(path)
    @img = Image.new(@window, path, true)
    @y1 = 0; @y2 = -HEIGHT
  end

  def draw
    @img.draw(0, @y2, ZOrder::Background) # Background 2 wird vor Background 1 gezeichnet,
    @img.draw(0, @y1, ZOrder::Background) # weil Background 1 über ihm liegen soll.
  end
end

class Img #Statisches Image => Zeichnen ohne Parameter möglich, Koordinaten und Maße abrufbar
  attr_accessor :x, :y
  def initialize(window, path, x, y, z, scr_x = 1, scr_y = 1)
    @window = window
    @image = Image.new(@window, path, false)
    @x = x; @y = y; @z = z
    @scr_x = scr_x; @scr_y = scr_y
  end

  def draw
    @image.draw(@x, @y, @z, @scr_x, @scr_y)
  end

  def width
    @image.width
  end

  def height
    @image.height
  end

  def mouse_inside?
    x = @window.mouse_x; y = @window.mouse_y
    x > @x and x < @x + width and y > @y and y < @y + height
  end
end

class Gosu::Window
  def buttons_down?(*buttons) #Überprüft mehrere Buttons gleichzeitig
    buttons.each{|b| return true if button_down?(b)}
    return false
  end

  #def button_up(id)
  #  not button_down(id)
  #end

  def click?(x_left, x_right, y_top, y_bottom)
    button_down?(Gosu::MsLeft) and mouse_x > x_left and mouse_x < x_right and mouse_y > y_top and mouse_y < y_bottom
  end

  def draw_line_b(x1, y1, c1, x2, y2, c2, z, b, mode)
    raise 'mode (last param) has to be :hor or :vert' if mode != :hor and mode != :vert
    b1 = b/2; b2 = b-b1
    if mode == :hor
      draw_quad(x1, y1-b2, c1, x2, y2-b2, c2, x2, y2+b1, c2, x1, y1+b1, c1, z)
    elsif mode == :vert
      draw_quad(x1-b2, y1, c1, x2-b2, y2, c2, x2+b1, y2, c2, x1+b1, y1, c1, z)
    end
  end
end

class ImgButton #Button mit gespeichertem Bild
  attr_accessor :x, :y, :active
  attr_reader :width, :height
  def initialize(window, image_path, x, y, z, scr_x = 1, scr_y = 1)
    @window = window
    @img = Img.new(window, image_path, x, y, z, scr_x, scr_y)
    @x = x
    @y = y
    @width = @img.width*scr_x
    @height = @img.height*scr_y
    @active = true
  end

  def click?
    @active? @window.click?(@x, @x + @width, @y, @y + @height) : false
  end
  
  def center_hor(left, right)
    @x = (right+left)/2 - @img.width/2
	  @img.x = @x
  end
  
  def center_vert(up, down)
    @y = (up+down)/2 - @img.height/2
	  @img.y = @y
  end

  def draw
    @img.draw if @active
  end
end

class Input_Box
  attr_reader :x, :y, :width, :height
  def initialize(window, x, y, z1, z2, width, height, font_size = 20)
    @window = window
    @x = x; @y = y; @z1 = z1; @z2 = z2
    @width = width; @height = height
    @font = Font.new(@window, "Arial", font_size)
    @text_input = TextInput.new
    @box_image = (height < 100)?Image.new(@window, "input_box_small.png", false):Image.new(@window, "input_box.png", false)
    @caret_counter = 0
  end

  def activate
    @window.text_input = @text_input
  end

  def deactivate
    @window.text_input = nil
  end

  def activated?
    @window.text_input == @text_input
  end

  def text
    @text_input.text
  end

  def text=(text)
    @text_input.text = text
  end

  def draw
    @box_image.draw(@x, @y, @z1, @width/@box_image.width.to_f, @height/@box_image.height.to_f)
    @font.draw(@text_input.text, @x+9, @y+3, @z2, 1.0, 1.0, 0xff000000)
    pos_x = @x + 10 + @font.text_width(@text_input.text[0...@text_input.caret_pos]); pos_y = @y + 2
    @caret_counter += 1; @caret_counter *= -1 if @caret_counter > 30
    @window.draw_line(pos_x, pos_y, 0xff000000, pos_x, pos_y + @font.height, 0xff000000, @z2) if @window.text_input == @text_input and @caret_counter >= 0
  end
end

class Gosu::Font
  def draw_centered(string, x, y, z = 1, factor_x = 1.0, factor_y = 1.0, color = 0xffffffff)
    draw(string, x-text_width(string)/2, y-height/2, z, factor_x, factor_y, color )
  end
  
  def draw_right(string, x, y, z = 1, factor_x = 1.0, factor_y = 1.0, color = 0xffffffff)
    draw(string, x-text_width(string), y, z, factor_x, factor_y, color )
  end
end

class Slide_Menu
  def initialize(window, x, y, z, c, options, font, width, start_index = 0, method = nil)
    @window = window
    @options = options
    @output_options = ((method)? @options.map{|e| e.send(method)} : @options )
    @font = font
    @width = width
    @akt_index = start_index
    @x = x; @y = y; @z = z; @c = c
    side_length = @font.height; height = Math.sqrt(side_length**2 + (side_length/2)**2)
    @t1 = [@x+height, @y, @c, @x+height, @y+side_length, @c, @x, @y+side_length/2, @c, @z]
    @t2 = [@x+@width, @y+side_length/2, @c, @x+@width-height, @y, @c, @x+@width-height, @y+side_length, @c, @z]
  end

  def akt_element
    @options[@akt_index]
  end

  def update_options(options, start_index = 0, method = nil)
    @options = options
    @output_options = ((method)? @options.map{|e| e.send(method)} : @options )
    @akt_index = start_index
  end

  def update
    x = @window.mouse_x; y = @window.mouse_y
    if    x > @t1[6] and x < @t1[0] and y > @t1[1] and y < @t1[4]
      @akt_index -= 1
      @akt_index = @options.size - 1 if @akt_index < 0
    elsif x > @t2[6] and x < @t2[0] and y > @t2[4] and y < @t2[7]
      @akt_index += 1
      @akt_index = 0 if @akt_index >= @options.size
    end
    @options[@akt_index]
  end

  def draw
    if @options.size > 1
      @window.draw_triangle(*@t1)
      @window.draw_triangle(*@t2)
    end
    @font.draw(@output_options[@akt_index], @x+(@width-@font.text_width(@output_options[@akt_index]))/2, @y, @z)
  end
end

class Mouse_Pointer #Zeigt die Maus im Gosu-Programm an, update und draw müssen ausgeführt werden.
  attr_accessor :visible
  def initialize(window, z)
    @window = window
    @img = Image.new(@window, "media/mouse.png", true)
    @x = 0; @y = 0; @z = z
    @visible = true
  end

  def update
    @x = @window.mouse_x
    @y = @window.mouse_y
  end

  def draw
    @img.draw(@x, @y, @z) if @visible
  end
end