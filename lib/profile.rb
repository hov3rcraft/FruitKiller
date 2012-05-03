#encoding: utf-8
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

  def add_game(score, game)
    @games_played += 1
    @score_sum    += score
    @last_score    = score
    if @high_scores[game]
      @high_scores[game] = score if score > @high_scores[game]
    else
      @high_scores[game] = score
    end
    @last_played   = Date.today
  end
end