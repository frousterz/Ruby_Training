# EXTRA CREDIT:
#
# Create a program that will play the Greed Game.
# Rules for the game are in GREED_RULES.TXT.
#
# You already have a DiceSet class and score function you can use.
# Write a player class and a Game class to complete the project.  This
# is a free form assignment, so approach it however you desire.

class Game
  attr_accessor :players

  def initialize(console)
    @console = console
    @players = []
    @dice_set = DiceSet.new
    @game_score = GameScore.new
    @player_factory = PlayerFactory.new
  end

  def start
    @console.start_game_msg
    number_of_players = @console.number_of_players
    player_names = @player_factory.player_names(number_of_players)
    @players = @player_factory.create_players(player_names)
    rounds
    @console.final_round_msg
    rounds(true)
    @console.score_table(@players)
    game_winner = @game_score.winner(@players)
    @console.winner_msg(game_winner)
  end

  def rounds(final_round = false)
    loop do
      @players.each do |player|
        @console.player_turn_msg(player)
        roll_chance(player) if @console.roll_dice?
        @console.player_points_msg(player)
        final_round = true if player.score >= 3000
      end
      break if final_round
    end
  end

  def roll_chance(player)
    player.roll_dices(@dice_set, 5)
    @console.obtained_dices(@dice_set.values, player)
    obtained_points, no_scored = @game_score.score_roll(@dice_set.values)
    game_scoring(player, obtained_points, no_scored)
  end

  def second_chance(player, no_scored)
    @console.chance_msg(no_scored)
    return unless @console.roll_dice_again?

    player.roll_dices(@dice_set, no_scored)
    @console.obtained_dices(@dice_set.values, player)
    points, = @game_score.score_roll(@dice_set.values)
    @game_score.asign_points(player, points)
  end

  def game_scoring(player, obtained_points, no_scored)
    if !player.enable
      if obtained_points >= 300
        @game_score.asign_points(player, obtained_points)
        enable_player(player)
      end
    else
      @game_score.asign_points(player, obtained_points)
      second_chance(player, no_scored) if no_scored >= 1 && obtained_points > 0
    end
  end

  def enable_player(player)
    player.enable = true
  end
end

class PlayerFactory
  def initialize
    @console = GameConsole.new
  end

  def create_players(player_names)
    players = []
    case player_names.size
    when 2..10
      player_names.each do |name|
        players << Player.new(name)
      end
    else
      raise GameError
    end
    players
  end

  def player_names(number_of_players)
    player_names = []
    number_of_players.times do |i|
      player_names << @console.ask_for_name(i)
    end
    player_names
  end
end

class DiceSet
  attr_accessor :values

  def initialize
    @values = []
  end

  def roll(roll_times)
    @values.clear
    roll_times.times do
      @values << rand(1..6)
    end
  end
end

class Player
  attr_accessor :name, :score, :enable

  def initialize(name)
    @name = name
    @score = 0
    @enable = false
  end

  def roll_dices(dices, roll_times)
    dices.roll(roll_times)
  end
end

class GameScore
  def asign_points(player, points)
    case points
    when 0
      player.score = 0
    else
      player.score += points
    end
  end

  def score_roll(dice)
    points = score(dice)
    no_scoring_dice = no_scoring(dice)
    [points, no_scoring_dice]
  end

  def winner(players)
    max_score = 0
    winner = Player.new('')
    players.each do |player|
      if player.score >= max_score
        winner = player
        max_score = player.score
      end
    end
    winner
  end

  def score(dice)
    return 0 if dice.empty?
    score = 0
    dice.uniq.each do |element|
      element_count = dice.count(element)
      score += points(element, element_count)
    end
    score
  end

  def no_scoring(dices)
    return 0 if dices.empty?
    no_score_dice = 0
    dices.uniq.each do |dice|
      dice_count = dices.count(dice)
      points = points(dice, dice_count)
      no_score_dice += dice_count if points <= 0
    end
    no_score_dice
  end

  def points(element, element_count)
    count_module = element_count % 3
    case element
    when 1
      element_count >= 3 ? 1000 + count_module * 100 : element_count * 100
    when 5
      element_count >= 3 ? 500 + 50 * count_module : element_count * 50
    else
      element_count >= 3 ? element * 100 : 0
    end
  end
end

class GameConsole
  def ask_for_name(number)
    print "Write a name for player #{number} >> "
    gets.chomp
  end

  def number_of_players
    print "How many players want to play the Greed Game? \n>> "
    gets.to_i
  end

  def roll_dice?
    puts 'Do you want to roll the dice? [yes/no]'
    response = gets.chomp.downcase
    response.eql? 'yes'
  end

  def roll_dice_again?
    puts 'Do you want to roll the dice again? [yes/no]'
    response = gets.chomp.downcase
    response.eql? 'yes'
  end

  def obtained_dices(dice_set, player)
    puts "#{player.name}, your dices are:"
    dice_set.each { |dice| print ">> #{dice}  " }
    puts ''
  end

  def chance_msg(no_scoring_dices)
    puts "You have #{no_scoring_dices} dice(s) to score"
  end

  def score_table(players)
    puts "\n*** Score Table ***"
    puts 'Player Name | Score'
    players.each do |player|
      puts "#{player.name} | #{player.score}"
    end
    puts "\n"
  end

  def final_round_msg
    puts "\n*******************************************"
    puts '* This is the Final Round, roll the dice! *'
    puts '*******************************************'
  end

  def player_turn_msg(player)
    puts "\nIt`s #{player.name}`s turn"
  end

  def player_points_msg(player)
    puts "You get #{player.score} points!"
  end

  def winner_msg(player)
    puts "\n****   Game Winner   ****"
    puts "The winner is #{player.name} with #{player.score} points!"
  end

  def start_game_msg
    puts '*********************************'
    puts '**                             **'
    puts '**  Welcome to the Greed Game  **'
    puts '**                             **'
    puts '*********************************'
  end
end
