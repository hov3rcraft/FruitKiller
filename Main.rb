#!/Users/mk/.rvm/bin/ruby-1.9.2-p180@gosu
# encoding: utf-8

VERSION = "2.0 Build 1"
DATE    = "2012-05-03"

require 'gosu'
require 'yaml'
require_relative 'lib/gosu_mod'
require_relative 'lib/element'
require_relative 'lib/game'
require_relative 'lib/game_window'
require_relative 'lib/highscores'
require_relative 'lib/profile'
include Gosu

WIDTH            = 1280
HEIGHT           = 800
ELEMENT_WIDTH    = 64

WHITE            = 0xFFFFFFFF
BLACK            = 0xFF000000
YELLOW           = 0XFFFFFF00
GREEN            = 0XFF00FF00
SOFT_GREEN       = 0XFF66FF66
BLUE             = 0XFF00BFFF
RED              = 0XFFFF0000
ORANGE           = 0XFFFF7700
GRAY             = 0X77444444

PREFERENCES_PATH = File.dirname(__FILE__)
MEDIA_PATH       = File.join(File.dirname(__FILE__), 'media')
PROFILES_FILE    = File.join(PREFERENCES_PATH, 'profiles.yml')
SCORES_FILE      = File.join(PREFERENCES_PATH, 'scores.yml')

module ZOrder
  Background, Menu, MenuString, InputBox, InputBoxString, Element, String = *0..6
end

class Fixnum
  def ord_string
    s = self.to_s
    case s[s.length-1]
    when "1"
      s + "st"
    when "2"
      s + "nd"
    when "3"
      s + "rd"
    else
      s + "th"
    end
  end
end

window = GameWindow.new
window.show