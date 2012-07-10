require 'player'

describe Player do
  before :each do
    @console = mock("console").as_null_object
    @board = mock("board").as_null_object
    @player = Player.new
    @player.console = @console
  end

  it "requests mark information from the console" do
    @console.should_receive("prompt_player_mark").and_return(0)
    @player.make_mark(@board)
  end

  it "checks for valid mark information" do
    @console.should_receive(:prompt_player_mark).and_return(0,1)
    @board.should_receive(:make_mark).once
    @board.should_receive(:is_available_space?).and_return(false,true)
    @player.make_mark(@board)
  end
end
