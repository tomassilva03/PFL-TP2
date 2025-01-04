% ai.pl - Contains the AI logic for choosing moves

% choose_move(+GameState, +Difficulty, -Move)
% Choose a move based on the difficulty level
%
% The `choose_move/3` predicate selects a move for the AI player based on the current game state and the specified difficulty 
% level. It follows these steps:
%
% 1. Extract Game State Information:
%    The predicate extracts the `Phase` and `BoardSize` from the `GameState` structure to determine whether the game is in 
%    the setup or play phase and the size of the board.
%
% 2. Generate Valid Moves:
%    The `valid_moves/2` predicate is called to generate a list of all valid moves for the current player based on the game state.
%
% 3. Select Move Based on Phase:
%    - If the game is in the `setup` phase, the `random_member/2` predicate is used to select a random move from the list 
%      of valid moves. This ensures that the AI places pieces randomly during the setup phase.
%
% 4. Select Move Based on Difficulty:
%    - If the game is in the `play` phase, the move selection is based on the specified difficulty level:
%      - Difficulty 1: The `random_member/2` predicate is used to select a random move from the list of valid moves.
%      - Difficulty 2: The `choose_greedy_move/3` predicate is called to select the move that maximizes the immediate value 
%        based on the greedy algorithm.
%      - Difficulty 3: The `minimax/4` predicate is called to select the move that maximizes the long-term value based on the 
%        minimax algorithm with an adaptive depth based on the board size:
%        - Board size 4: Depth 6
%        - Board size 5: Depth 4
%        - Board size 6: Depth 3
%        - Board size 7 and above: Depth 2
%
% 5. Print the Selected Move:
%    The `format/2` predicate is used to print the selected move to the console for debugging purposes.
%
% The `choose_move/3` predicate ensures that the AI selects an appropriate move based on the current game phase and difficulty 
% level, providing a challenging opponent for the player.
% Main predicate
choose_move(GameState, Difficulty, Move) :-
    GameState = state(_, _, _, Phase, _),
    valid_moves(GameState, Moves),
    choose_strategy(Phase, Difficulty, Strategy),
    call(Strategy, GameState, Moves, Move),
    format('Computer chooses move: ~w~n', [Move]).


% value(+GameState, +Move, -Value)
% Calculate the value of a move by simulating the move and evaluating the resulting game state
%
% The `value/3` predicate evaluates the potential outcome of a move by simulating its effect on the game state and 
% calculating a score. It follows these steps:
%
% 1. Extract Move Coordinates:
%    The predicate extracts the coordinates `(Y1, X1)` and `(Y2, X2)` from the `Move` structure, which represents stacking 
%    a piece from `(Y1, X1)` to `(Y2, X2)`.
%
% 2. Simulate the Move:
%    The `move/3` predicate is called to apply the move to the current `GameState`, resulting in a new game state 
%    `state(NewBoard, _, _, _, BoardSize)`. This simulates the effect of the move on the board.
%
% 3. Extract the New Stack:
%    The predicate uses `nth1/3` to access the row `Row` at position `Y2` in the `NewBoard`, and then accesses the 
%    cell at position `X2` in that row. This cell contains the new stack created by the move, represented as `Player-NewCount`.
%
% 4. Calculate the Value:
%    The value of the move is determined by the height of the new stack, `NewCount`. This value is assigned to the 
%    `Value` variable.
%
% The `value/3` predicate provides a way to evaluate the effectiveness of a move by considering the resulting stack 
% height, which is useful for AI decision-making.

% Calculate the value of a move during the play phase
value(GameState, Move, Value) :-
    GameState = state(_, Player, _, Phase, _),
    Phase = play,
    Move = stack(Y1, X1, Y2, X2),
    move(GameState, stack(Y1, X1, Y2, X2), state(NewBoard, _, _, _, BoardSize)),
    nth1(Y2, NewBoard, Row),
    nth1(X2, Row, Player-NewCount),
    Value is NewCount.

% Calculate the value of a move during the setup phase
value(GameState, Move, Value) :-
    Move = place(Y, X),
    GameState = state(Board, Player, _, Phase, _),
    Phase = setup,
    proximity(Board, Y, X, Player, OpponentProximity, FriendlyProximity),
    center_of_board(Board, Y, X, CenterScore),
    % Adjusted formula: prioritize center, friendly proximity, and disruption
    Value is (FriendlyProximity * 2) + OpponentProximity + (CenterScore * 3).

% Choose the best move based on the greedy algorithm
choose_greedy_move(GameState, Moves, BestMove) :-
    GameState = state(_, _, _, Phase, _),
    Phase = play,
    findall(Value-Move, (
        member(Move, Moves),
        value(GameState, Move, Value)
    ), MoveValues),
    max_member(_-BestMove, MoveValues).

% Choose the best move based on the greedy algorithm during the setup phase
choose_greedy_move(GameState, Moves, BestMove) :-
    GameState = state(_, _, _, Phase, _),
    Phase = setup,
    % Generate a list of Value-Move pairs
    findall(Value-Move, (
        member(Move, Moves),
        value(GameState, Move, Value)
    ), MoveValues),
    format("Move Values: ~w~n", [MoveValues]),
    
    % Find the maximum value
    findall(Value, member(Value-_, MoveValues), Values),
    max_member(MaxValue, Values),
    format("Max Value: ~w~n", [MaxValue]),
    
    % Collect all moves with the maximum value
    findall(Move, member(MaxValue-Move, MoveValues), BestMoves),
    format("Best Moves: ~w~n", [BestMoves]),
    
    % Choose a random move from the best moves
    random_member(BestMove, BestMoves),
    format("Best Move: ~w~n", [BestMove]).

% Determine the value for the minimax algorithm
minimax_value(GameState, Depth, Value) :-
    minimax(GameState, Depth, _, Value).

minimax(GameState, Depth, BestMove, BestValue) :-
    Depth > 0,
    GameState = state(_, Player, _, _, _),
    valid_moves(GameState, Moves),
    Moves \= [],
    NewDepth is Depth - 1,
    format("Depth: ~d, Player: ~w~n", [Depth, Player]),
    findall(Value-Move, (
        member(Move, Moves),
        move(GameState, Move, NewGameState),
        minimax_value(NewGameState, NewDepth, Value)
    ), MoveValues),
    max_member(BestValue-BestMove, MoveValues),
    format("    Best Move: ~w, Value: ~d~n", [BestMove, BestValue]).


% Base case: when depth is 0, evaluate moves directly
minimax(GameState, 0, BestMove, BestValue) :-
    valid_moves(GameState, Moves),
    findall(Value-Move, (
        member(Move, Moves),
        move(GameState, Move, NewGameState),
        evaluate_move(GameState, Move, NewGameState, Value)
    ), MoveValues),
    max_member(BestValue-BestMove, MoveValues).

% Fallback if no moves are available
minimax(GameState, _, _, Value) :-
    valid_moves(GameState, Moves),
    Moves = [],
    format("No valid moves. Evaluating game state: ~w~n", [GameState]),
    evaluate(GameState, Value),
    format("    Game State Value: ~d~n", [Value]).


evaluate_move(_, Move, NewGameState, Value) :-
    Move = stack(Y1, X1, Y2, X2),
    NewGameState = state(NewBoard, _, _, _, _),
    nth1(Y2, NewBoard, Row),
    nth1(X2, Row, Player-NewCount),
    proximity(NewBoard, Y2, X2, Player, OpponentProximity, FriendlyProximity),
    % Combine the criteria into a weighted value
    Value is NewCount * 3 + FriendlyProximity + OpponentProximity.
    format("Evaluating Move: stack(~d, ~d, ~d, ~d)~n", [Y1, X1, Y2, X2]),
    format("    Stack Height: ~d, Opponent Proximity: ~d, Friendly Proximity: ~d, Value: ~d~n",
           [NewCount, OpponentProximity, FriendlyProximity, Value]).

default_min_list([], Default, Default).
default_min_list(List, _, Min) :- min_list(List, Min).

proximity(Board, Y, X, Player, OpponentProximity, FriendlyProximity) :-
    opponent(Player, Opponent),
    findall(Distance, (
        nth1(Y1, Board, Row),
        nth1(X1, Row, Opponent-_),
        manhattan_distance(X, Y, X1, Y1, Distance)
    ), OpponentDistances),
    findall(Distance, (
        nth1(Y1, Board, Row),
        nth1(X1, Row, Player-_),
        (X1 \= X ; Y1 \= Y),  % Exclude the current piece
        manhattan_distance(X, Y, X1, Y1, Distance)
    ), FriendlyDistances),
    default_min_list(OpponentDistances, 1000, OpponentProximity),
    default_min_list(FriendlyDistances, 0, FriendlyProximity).

% Evaluate the game state by finding the tallest stack created by the player and minimizing opponent's advantage
evaluate(GameState, Score) :-
    GameState = state(Board, Player, _, _, BoardSize),
    findall(Count, (
        member(Row, Board),
        member(Player-Count, Row)
    ), Counts),
    max_member(TallestStack, Counts),
    opponent(Player, Opponent),
    findall(OpponentDistance, (
        nth1(Y1, Board, Row),
        nth1(X1, Row, Player-Count),
        Count > 0,
        findall(Distance, (
            nth1(Y2, Board, OpponentRow),
            nth1(X2, OpponentRow, Opponent-OpponentCount),
            nonvar(Count),
            nonvar(OpponentCount),
            manhattan_distance(X1, Y1, X2, Y2, Distance)
        ), Distances),
        min_list(Distances, OpponentDistance)
    ), OpponentDistances),
    sumlist(OpponentDistances, TotalOpponentDistance),
    findall(PlayerDistance, (
        nth1(Y1, Board, Row),
        nth1(X1, Row, Player-Count),
        Count > 0,
        findall(Distance, (
            nth1(Y2, Board, PlayerRow),
            nth1(X2, PlayerRow, Player-PlayerCount),
            nonvar(Count),
            nonvar(PlayerCount),
            manhattan_distance(X1, Y1, X2, Y2, Distance)
        ), Distances),
        min_list(Distances, PlayerDistance)
    ), PlayerDistances),
    sumlist(PlayerDistances, TotalPlayerDistance),
    Score is TallestStack - TotalOpponentDistance + TotalPlayerDistance.

% Calculate the Manhattan distance between two coordinates
manhattan_distance(X1, Y1, X2, Y2, Distance) :-
    Distance is abs(X1 - X2) + abs(Y1 - Y2).

% Calculate the absolute value of a number
abs(X, AbsX) :-
    (X >= 0 ->
        AbsX = X
    ;
        AbsX is -X
    ).

% Find the minimum value in a list
min_list([Min], Min).
min_list([H|T], Min) :-
    min_list(T, MinTail),
    Min is min(H, MinTail).

% Determine the opponent player
opponent(blue, white).
opponent(white, blue).
opponent(blueH, whitePC).
opponent(whitePC, blueH).
opponent(bluePC, whiteH).
opponent(whiteH, bluePC).
opponent(computer1, computer2).
opponent(computer2, computer1).

center_of_board(Board, Y, X, CenterScore) :-
    length(Board, Size),
    MaxDistance is (Size - 1) * 2,  % Maximum Manhattan distance on the board
    CenterY is (Size + 1) // 2,
    CenterX is (Size + 1) // 2,
    manhattan_distance(X, Y, CenterX, CenterY, Distance),
    CenterScore is MaxDistance - Distance.

% Mapping for move selection based on phase and difficulty
choose_strategy(setup, 1, random_strategy).
choose_strategy(setup, 2, greedy_strategy).
choose_strategy(setup, 3, random_strategy).
choose_strategy(play, 1, random_strategy).
choose_strategy(play, 2, greedy_strategy).
choose_strategy(play, 3, minimax_strategy).

% random_strategy(+Moves, -Move)
% Choose a random move from the list of valid moves
random_strategy(GameState, Moves, Move) :-
    random_member(Move, Moves).

% greedy_strategy(+GameState, +Moves, -Move)
% Choose the move that maximizes the immediate value based on the greedy algorithm
greedy_strategy(GameState, Moves, Move) :-
    choose_greedy_move(GameState, Moves, Move).

% minimax_strategy(+GameState, +Moves, -Move)
% Dynamically determines the depth based on the board size and chooses the best move using minimax.
minimax_strategy(GameState, Moves, Move) :-
    GameState = state(_, _, _, _, BoardSize),
    determine_depth(BoardSize, Depth),  % Determine depth dynamically based on board size
    minimax(GameState, Depth, Move, _).

% Fact-based depth determination
determine_depth(BoardSize, 6) :- BoardSize = 4.  % Small boards (4x4)
determine_depth(BoardSize, 3) :- BoardSize >= 5, BoardSize =< 6.  % Medium boards (5x5 and 6x6)
determine_depth(BoardSize, 2) :- BoardSize >= 7.  % Large boards (7x7 and above)