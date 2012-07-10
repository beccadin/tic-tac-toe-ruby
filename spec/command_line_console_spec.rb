require 'command_line_console'

describe "CommandLineConsole" do
  before :each do
    @console = CommandLineConsole.new
    @players = [:player1,:player2]
    @console.set_players(@players)
    @spaces_blank = [nil]*9
    @spaces_with_marks = [nil,@players.first,@players.last]*3
  end

  it "assigns ASCII characters to players in 'Game'" do
    @console.characters[:player1].should eql 'O'
    @console.characters[:player2].should eql 'X'
  end

  it "creates an array of strings representing the board" do
    @board = mock("board")
    @board.should_receive(:size).any_number_of_times.and_return(3)
    [
      [@spaces_blank, ["_|_|_"]*3],
      [@spaces_with_marks, ["_|O|X"]*3],
    ].each do |spaces, expected|
      @board.should_receive(:spaces).and_return(spaces)
      @console.convert_board_to_ascii(@board).should eql expected
    end
  end

  it "creates an array of strings representing available board spaces" do
    @board = mock("board")
    @board.should_receive(:size).any_number_of_times.and_return(3)
    [
      [@spaces_blank, ["1 2 3","4 5 6","7 8 9"]],
      [@spaces_with_marks, ["1    ","4    ","7    "]],
    ].each do |spaces, expected|
      @board.should_receive(:spaces).and_return(spaces)
      @console.available_spaces_to_ascii(@board).should eql expected
    end
  end
end
