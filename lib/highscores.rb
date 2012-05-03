#encoding: utf-8

Score = Struct.new(:points, :name, :date) do
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