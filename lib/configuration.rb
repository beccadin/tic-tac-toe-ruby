require 'human'
require 'computer_dumb'
require 'computer_impossible'

class Configuration
  attr_reader :console, :players, :assigned_symbols

  PLAYER_CLASSES = [Human, DumbComputer, ImpossibleComputer]

  def initialize(console)
    @console = console
    @players = []
    @assigned_symbols = {}
  end

  def choose_player
    @players << Human.new
  end

  def choose_opponent
    @players << @console.prompt_opponent_type(PLAYER_CLASSES).new
  end

  def assign_symbols
    @players.each_with_index do |player, index|
      @assigned_symbols["player#{index}".to_sym] = player
    end
  end
end
