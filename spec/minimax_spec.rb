require 'minimax'
require 'minimax_cache'
require 'board'

describe Minimax do
  before :each do
    @minimax = Minimax.new(9)
    @minimax.max_mark = :max_mark
    @minimax.min_mark = :min_mark
    @board = Board.new
  end

  it "#initialize receives a depth limit value (default of 7)" do
    Minimax.new.depth_limit.should == 7
    Minimax.new(6).depth_limit.should == 6
  end

  it "#initialize sets current depth to 0" do
    @minimax.current_depth.should == 0
  end

  it "#initialize instantiates a MinimaxCache object" do
    @minimax.cache.should be_instance_of(MinimaxCache)
  end

  context "with mocks" do
    it "returns 1 for max_mark win" do
      @board.stub!(:winning_solution?).with(:min_mark).and_return(false)
      @board.stub!(:winning_solution?).with(:max_mark).and_return(true)
      @minimax.score(@board,:max_mark).should eql 1
    end

    it "returns -1 for min_mark win" do
      @board.stub!(:winning_solution?).with(:min_mark).and_return(true)
      @board.stub!(:winning_solution?).with(:max_mark).and_return(false)
      @minimax.score(@board,:max_mark).should eql -1
    end

    it "returns 0 for no win and board full" do
      @board.stub!(:winning_solution?).and_return(false)
      @board.stub!(:spaces_with_mark).with(Board::BLANK).and_return([])
      @minimax.score(@board,:max_mark).should eql 0
    end

    it "calls 'score' recursively until board full" do
      @board.stub!(:winning_solution?).and_return(false)
      @board.should_receive(:spaces_with_mark).and_return([0],[])
      @minimax.score(@board,:max_mark)
    end

    it "calls 'score' recursively until winning solution" do
      limit_recursion_using_winning_solution(2)
      @board.stub!(:spaces_with_mark).and_return([0])
      @minimax.score(@board,:max_mark)
    end

    it "marks the board with opposing mark, then restores mark" do
      marking_order = []
      @board.stub!(:spaces_with_mark).and_return([3])
      @board.should_receive(:make_mark).twice {|i,mark|
        marking_order << mark
      }
      limit_recursion_using_winning_solution(1)
      
      @minimax.score(@board,:max_mark)
      marking_order.should == [:min_mark, Board::BLANK]
    end

    it "calls 'score' for each available space on board" do
      set_should_receive_marks([[2,:min_mark],[3,:min_mark]])
      @board.stub!(:winning_solution?).and_return(false)
      @board.stub!(:spaces_with_mark).and_return([2,3],[],[])
      @minimax.score(@board,:max_mark)
    end

    it "returns highest score if opponent is max_mark and won" do
      set_winning_solutions_with(:max_mark,[false]*3 + [true])
      set_winning_solutions_with(:min_mark,[false]*2 + [true] + [false])
      @board.should_receive(:spaces_with_mark).and_return([1,2,3],[])
      @minimax.score(@board,:min_mark).should eql 1 
    end

    it "returns lowest score if opponent is min_mark and won" do
      set_winning_solutions_with(:min_mark,[false]*3 + [true])
      set_winning_solutions_with(:max_mark,[false]*2 + [true] + [false])
      @board.should_receive(:spaces_with_mark).and_return([1,2,3],[])
      @minimax.score(@board,:max_mark).should eql -1
    end

    it "discards initialized value when comparing recursive scores" do
      set_winning_solutions_with(:max_mark,[false]*4)
      set_winning_solutions_with(:min_mark,[false] + [true]*3)
      @board.should_receive(:spaces_with_mark).and_return([1,2,3])
      @minimax.score(@board,:min_mark).should eql -1
    end
  end

  context "without mocks" do
    before :each do
      @board = Board.new
    end

    it "returns 1 for max_mark win" do
      make_marks([0,1,2],:max_mark)
      @minimax.score(@board,:max_mark).should eql 1
    end

    it "returns -1 for min_mark win" do
      make_marks([0,1,2],:min_mark)
      @minimax.score(@board,:min_mark).should eql -1
    end

    it "returns 0 for no win and board full" do
      make_marks([0,2,3,5,7],:min_mark)
      make_marks([1,4,6,8],:max_mark)
      @minimax.score(@board,:max_mark).should eql 0
    end

    it "calls 'score' recursively until board full" do
      each_space = (0..8).collect {|i| [i]}
      @board.stub!(:winning_solution?).and_return(false)
      @board.should_receive(:spaces_with_mark).and_return(*each_space,[])

      marking_order = []
      @board.stub!(:make_mark) {|space| marking_order << space}

      @minimax.score(@board, :min_mark)
      marking_order.should == (each_space + each_space.reverse).flatten
    end

    it "calls 'score' recursively until winning solution" do
      each_space = (0..8).collect {|i| [i]}
      @board.stub!(:spaces_with_mark).and_return(*each_space,[])
      limit_recursion_using_winning_solution(5)

      marking_order = []
      @board.stub!(:make_mark) {|space| marking_order << space}

      @minimax.score(@board, :min_mark)
      marking_order.should eql [0,1,2,3,4,4,3,2,1,0]
    end

    it "returns a hash of spaces and scores" do
      make_marks([0, 2, 5], :max_mark)
      make_marks([1, 3, 4], :min_mark)
      expected = {6 => -1, 7 => 0, 8 => 1}
      @minimax.scores(@board, :max_mark).should eql expected
    end

    it "stops scoring when best score is found" do
      make_marks([0, 2, 7], :min_mark)
      make_marks([4, 5], :max_mark)
      expected = {1 => 0, 3 => 1}
      @minimax.scores(@board, :max_mark).should eql expected
    end
  end

  context "using depth limit" do
    before :each do
      @board = Board.new
      make_marks([0], :max_mark)
      make_marks([3, 5], :min_mark)
    end

    it "scores correctly with limit of zero" do
      expected = {1 => 0, 2 => 0, 4 => 0, 6 => 0, 7 => 0, 8 => 0}
      @minimax.depth_limit = 0
      @minimax.scores(@board, :max_mark).should == expected
    end

    it "scores correctly with limit of one" do
      expected = {1 => -1, 2 => -1, 4 => 0, 6 => -1, 7 => -1, 8 => -1}
      @minimax.depth_limit = 1
      @minimax.scores(@board, :max_mark).should == expected
    end

    it "scores correctly with limit of three" do
      expected = {1 => -1, 2 => -1, 4 => 1}
      @minimax.depth_limit = 4
      @minimax.scores(@board, :max_mark).should == expected
    end
  end

  it "#score adds board spaces to cache with the score" do
    @board.stub!(:winning_solution?).with(:min_mark).and_return(true)
    @board.stub!(:winning_solution?).with(:max_mark).and_return(false)
    @minimax.score(@board, :max_mark)
    @minimax.cache.get_score(@board.spaces).should == -1
  end

  it "#scores uses cached scores if available" do
    cache_moves(@board.spaces, :max_mark, 10)
    expected = Hash[(0..8).map {|i| [i, 10]}]
    @minimax.scores(@board, :max_mark).should == expected
  end

  private
  def score_variations(variations, score)
    Hash[variations.zip [score]*variations.length]
  end

  def next_move_variations(spaces, symbol)
    blank_indices = (0..spaces.length).select {|index| spaces[index] == Board::BLANK}
    blank_indices.map {|blank|
      spaces.map.with_index {|sym, index| index == blank ? symbol : sym}
    }
  end

  def cache_moves(spaces, symbol, score)
    moves = next_move_variations(spaces, symbol)
    @minimax.cache.map.merge!(score_variations(moves, score))
  end

  def limit_recursion_using_winning_solution(limit)
    returns = [false]*(limit * 2 + 1) + [true]
    @board.stub!(:winning_solution?).and_return(*returns)
  end

  def set_should_receive_marks(calls)
    calls.each {|space,mark|
      @board.should_receive(:make_mark).with(space,mark)
      @board.should_receive(:make_mark).with(space,Board::BLANK)
    }
  end

  def set_winning_solutions_with(mark,solutions)
    @board.should_receive(:winning_solution?).with(mark)
    .and_return(*solutions)
  end

  def make_marks(spaces,mark)
    spaces.each do |space| @board.make_mark(space,mark) end
  end
end
