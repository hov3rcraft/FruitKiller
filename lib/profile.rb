#encoding: utf-8
class Profile
  attr_reader :name, :games_played, :score_sum, :last_score, :high_scores, :vs_games_played, :ss_games_won, :ss_games_lost, :last_played
  def initialize(name)
    @name = name
    @games_played    = 0
    @score_sum       = 0
    @last_score      = 0
    @high_scores     = {}
    @vs_games_played = 0
    @ss_games_won    = 0
    @ss_games_lost   = 0
    @last_played     = Date.today
  end

  def add_game(score, game)
    @games_played += 1
    @score_sum    += score
    @last_score    = score
    @last_played   = Date.today
    if @high_scores[game]
      @high_scores[game] = score if score > @high_scores[game]
    else
      @high_scores[game] = score
    end
  end

  def add_splitscreen_game(won)
    @vs_games_played += 1
    (won)? @ss_games_won += 1 : @ss_games_lost += 1
    @last_played = Date.today
  end
end