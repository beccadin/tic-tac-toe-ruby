require 'command_line_console'
require 'command_line_prompter'
require 'command_line_renderer'

describe "CommandLineConsole" do
  before :all do
    @input = StringIO.new('', 'r+')
    @output = StringIO.new('', 'w')
    @players = [:player1, :player2]
    @symbol_map = {:player1 => :P1, :player2 => :P2}
  end

  before :each do
    @input.reopen('', 'r+')
    @output.reopen('', 'w')
    @console = CommandLineConsole.new(@input, @output)
    @renderer = @console.renderer
    @prompter = @console.prompter
  end

  it "#initialize defaults input/output to $stdin/$stdout" do
    console = CommandLineConsole.new
    console.in.should equal $stdin
    console.out.should equal $stdout
  end

  it "#assign_marks issues a prompt through a prompter" do
    @console.should_receive(:prompt_mark_symbol).and_return('O')
    @console.assign_marks(@symbol_map)
  end

  it "#assign_marks assigns ASCII characters to players" do
    set_console_characters
    @console.characters[:player1].should eql 'O'
    @console.characters[:player2].should eql 'X'
  end

  it "#prompt_player_mark limits prompter input to augmented array argument" do
    space_indices = [0, 1, 2, 5, 7]
    space_choices = ['1', '2', '3', '6', '8']
    @prompter.stub!(:request).and_return(1)
    @prompter.should_receive(:valid_input=).with(space_choices)
    @console.prompt_player_mark(space_indices)
  end

  it "#prompt_player_mark issues request for player move" do
    message = "Please choose the number of the space for your mark: "
    @prompter.should_receive(:request).with("\n", message).and_return(2)
    @prompter.stub!(:valid_input=)
    @console.prompt_player_mark([])
  end

  it "#prompt_player_mark returns integer one less than input" do
    @prompter.stub!(:valid_input=)
    @prompter.stub!(:request).and_return(5)
    @console.prompt_player_mark([]).should == 4
  end

  context "#prompt_board_size" do
    before :each do
      @input.reopen("3x3", 'r+')
    end

    it "limits prompter input to 3x3 and 4x4" do
      @prompter.should_receive(:valid_input=).with(["3x3", "4x4"])
      @console.prompt_board_size
    end

    it "issues request for board size" do
      message = "Enter the size of the board ('3x3' or '4x4'): "
      @prompter.should_receive(:request).with("\n", message)
      @console.prompt_board_size
    end

    it "returns an integer for board size" do
      @console.prompt_board_size.should == 3
      @input.reopen("4x4", 'r+')
      @console.prompt_board_size.should == 4
    end
  end

  it "prompts the user to play again" do
    @output.should_receive(:print).exactly(3).times
    @input.should_receive(:gets).and_return('a', '1', 'y')
    @console.prompt_play_again.should == true
  end

  it "prompts the user to choose a mark" do
    @output.should_receive(:print).exactly(3).times
    @input.should_receive(:gets).and_return('a', 'x', 'X')
    @console.prompt_mark_symbol.should == 'X'
  end

  context "when prompting the user to specify an opponent" do
    before :each do
      @opponent_options = [:human,:computer]
    end

    it "accepts an input within a valid range" do
      @input.reopen('1', 'r')
      @console.prompt_opponent_type(@opponent_options).should == :human
    end

    it "continues prompting until receiving a valid input" do
      @output.should_receive(:print).exactly(3).times
      @input.should_receive(:gets).and_return('0', '3', '1')
      @console.prompt_opponent_type(@opponent_options).should == :human
    end
  end

  it "#display_game_winner prints a message to the terminal" do
    set_console_characters
    @symbol_map.keys.each do |symbol|
      message = "Player #{@console.characters[symbol]} is the winner!"
      @console.out.should_receive(:puts).with("", message)
      @console.display_game_winner(symbol)
    end
  end

  it "#display_game_draw prints a message to the terminal" do
    message = "The game has ended with a draw!"
    @console.out.should_receive(:puts).with("", message)
    @console.display_game_draw
  end

  context "#display_board" do
    before :each do
      @board = mock("Board").as_null_object
    end

    it "converts board to ascii" do
      @renderer.should_receive(:board_to_ascii).and_return([])
      @console.display_board(@board)
    end

    it "displays a board of size 3" do
      @renderer.stub!(:board_to_ascii).and_return(["_|_|_", "X|O|_", "_|X|O"])
      formatted = ["     _|_|_", "     X|O|_", "     _|X|O"]
      @output.should_receive(:puts).with("", *formatted)
      @console.display_board(@board)
    end

    it "displays a board of size 4" do
      ascii = ["_|_|_|_", "X|_|O|_", "_|X|X|_", "O|O|O|O"]
      @renderer.stub!(:board_to_ascii).and_return(ascii)
      formatted = ["     _|_|_|_", "     X|_|O|_", "     _|X|X|_", "     O|O|O|O"]
      @output.should_receive(:puts).with("", *formatted)
      @console.display_board(@board)
    end
  end

  context "#display_board_choices" do
    before :each do
      @board = mock("Board").as_null_object
      board_ascii = ["_|_|_", "X|O|_", "_|X|O"]
      choices_ascii = ["1 2 3", "    6", "7    "]
      @renderer.stub!(:board_to_ascii).and_return(board_ascii)
      @renderer.stub!(:available_spaces_to_ascii).and_return(choices_ascii)
    end

    it "converts available spaces" do
      @renderer.should_receive(:available_spaces_to_ascii)
      @console.display_board_choices(@board)
    end

    it "converts board to ascii" do
      @renderer.should_receive(:board_to_ascii)
      @console.display_board_choices(@board)
    end

    it "displays the board with choices" do
      formatted = [ "     _|_|_     1 2 3", 
                    "     X|O|_         6",
                    "     _|X|O     7    "] 
      @output.should_receive(:puts).with("", *formatted)
      @console.display_board_choices(@board)
    end

    it "displays a size 4 board with choices" do
      board_ascii = ["_|_|_|_"]*4
      choices_ascii = [" 1  2  3  4", " 5  6  7  8", " 9 10 11 12", "13 14 15 16"]
      @renderer.stub!(:board_to_ascii).and_return(board_ascii)
      @renderer.stub!(:available_spaces_to_ascii).and_return(choices_ascii)
      formatted = [ "     _|_|_|_      1  2  3  4",
                    "     _|_|_|_      5  6  7  8",
                    "     _|_|_|_      9 10 11 12",
                    "     _|_|_|_     13 14 15 16"]
      @output.should_receive(:puts).with("", *formatted)
      @console.display_board_choices(@board)
    end
  end

  it "#prompt_player_order gives first turn to player with 'X' mark" do
    @console.stub!(:prompt_mark_symbol).and_return('X')
    @console.assign_marks({:player1 => :P1, :player2 => :P2})
    @console.prompt_player_order.should == [:player1, :player2]
    @console.stub!(:prompt_mark_symbol).and_return('O')
    @console.assign_marks({:player1 => :P1, :player2 => :P2})
    @console.prompt_player_order.should == [:player2, :player1]
  end

  private
  def set_console_characters
    @console.stub!(:prompt_mark_symbol).and_return('O')
    @console.assign_marks(@symbol_map)
  end
end
