% ai.pl - Contains the AI logic for choosing moves

% choose_move(+GameState, +Difficulty, -Move)
%
% The `choose_move/3` predicate selects a move for the AI player based on the current game state and the specified difficulty 
% level. This updated implementation eliminates nested conditionals by delegating the move selection to phase- and 
% difficulty-specific strategies.
%
% Workflow:
% 1. **Extract Game Phase and Generate Valid Moves**:
%    - The `Phase` is extracted from the `GameState` structure to determine if the game is in the `setup` or `play` phase.
%    - The `valid_moves/2` predicate generates a list of all valid moves for the current player based on the game state.
%
% 2. **Select a Strategy Based on Phase and Difficulty**:
%    - The `choose_strategy/3` predicate determines the strategy to use for move selection based on the current phase and 
%      difficulty level. It maps:
%        - `setup` phase:
%          - Difficulty 1: Random move selection using `random_strategy/3`.
%          - Difficulty 2: Greedy move selection using `greedy_strategy/3`.
%          - Difficulty 3: Random move selection using `random_strategy/3`.
%        - `play` phase:
%          - Difficulty 1: Random move selection using `random_strategy/3`.
%          - Difficulty 2: Greedy move selection using `greedy_strategy/3`.
%          - Difficulty 3: Minimax-based move selection using `minimax_strategy/3`.
%
% 3. **Dynamic Depth for Minimax Strategy**:
%    - The `minimax_strategy/3` predicate dynamically determines the depth of the search based on the board size:
%      - Board size ≤ 4: Depth 6
%      - Board size = 5: Depth 4
%      - Board size = 6: Depth 3
%      - Board size ≥ 7: Depth 2
%
% 4. **Execute the Selected Strategy**:
%    - The selected strategy is invoked using the `call/4` predicate, passing the current game state and valid moves.
%
% 5. **Output the Selected Move**:
%    - The selected move is printed to the console using `format/2` for debugging or logging purposes.
%
% The `choose_move/3` predicate provides a modular and extensible approach to AI move selection by separating the move
% selection logic into distinct strategies based on the game phase and difficulty level.
choose_move(GameState, Difficulty, Move) :-
    GameState = state(_, _, _, Phase, _),
    valid_moves(GameState, Moves),
    choose_strategy(Phase, Difficulty, Strategy),
    call(Strategy, GameState, Moves, Move),
    format('Computer chooses move: ~w~n', [Move]).


% value(+GameState, +Move, -Value)
%
% The `value/3` predicate evaluates the potential outcome of a move by simulating its effect on the game state or analyzing 
% its strategic position. The calculated value is used to guide AI decision-making during the game. The behavior differs 
% based on whether the game is in the **play phase** or the **setup phase**.
%
% 1. ** Play Phase: Evaluating Stacking Moves**
% - In the play phase, a move involves stacking pieces from one position to another.
% - Steps:
%   1. The move is represented as `stack(Y1, X1, Y2, X2)`, indicating that the stack at `(Y1, X1)` is moved to `(Y2, X2)`.
%   2. The `move/3` predicate is called to simulate the move, resulting in an updated game state.
%   3. The height of the new stack at `(Y2, X2)` is extracted from the updated board.
%   4. The value of the move is determined by the height (`NewCount`) of the resulting stack.
% - This approach prioritizes moves that create taller stacks, which are key to winning the game.
%
% 2. ** Setup Phase: Evaluating Placement Moves**
% - In the setup phase, a move involves placing a piece on a neutral cell.
% - Steps:
%   1. The move is represented as `place(Y, X)`, indicating a placement at `(Y, X)`.
%   2. The `proximity/5` predicate calculates the proximity of the position `(Y, X)` to:
%      - Friendly pieces (`FriendlyProximity`): Encourages clustering for future stacking.
%      - Opponent pieces (`OpponentProximity`): Encourages disruption of opponent strategy.
%   3. The `center_of_board/4` predicate calculates the proximity to the center of the board, encouraging central control.
%   4. A weighted formula combines these factors:
%      - Friendly proximity is weighted higher to encourage clustering.
%      - Opponent proximity and central control are secondary priorities.
% - The resulting value guides placement decisions, balancing offensive and defensive strategies.
%
% 3. ** Formula for Setup Phase:**
% `Value is (FriendlyProximity * 2) + OpponentProximity + (CenterScore * 3)`
% - **Friendly Proximity**: Encourages clustering for stronger stacks.
% - **Opponent Proximity**: Encourages moves closer to opponents to disrupt their plans.
% - **Center Score**: Rewards positions closer to the center for better control.
%
% The `value/3` predicate seamlessly handles both phases, allowing the AI to evaluate moves effectively throughout the game.

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
    
    % Find the maximum value
    findall(Value, member(Value-_, MoveValues), Values),
    max_member(MaxValue, Values),
    
    % Collect all moves with the maximum value
    findall(Move, member(MaxValue-Move, MoveValues), BestMoves),
    
    % Choose a random move from the best moves
    random_member(BestMove, BestMoves).

% Determine the value for the minimax algorithm
minimax_value(GameState, Depth, Value) :-
    minimax(GameState, Depth, _, Value).

% Recursive case: when depth is greater than 0, recursively evaluate moves
minimax(GameState, Depth, BestMove, BestValue) :-
    Depth > 0,
    GameState = state(_, Player, _, _, _),
    valid_moves(GameState, Moves),
    Moves \= [],
    NewDepth is Depth - 1,
    findall(Value-Move, (
        member(Move, Moves),
        move(GameState, Move, NewGameState),
        minimax_value(NewGameState, NewDepth, Value)
    ), MoveValues),
    max_member(BestValue-BestMove, MoveValues).

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
    evaluate(GameState, Value).

% Evaluate the move based on the resulting game state
evaluate_move(_, Move, NewGameState, Value) :-
    Move = stack(Y1, X1, Y2, X2),
    NewGameState = state(NewBoard, _, _, _, _),
    nth1(Y2, NewBoard, Row),
    nth1(X2, Row, Player-NewCount),
    proximity(NewBoard, Y2, X2, Player, OpponentProximity, FriendlyProximity),
    % Combine the criteria into a weighted value
    Value is NewCount * 3 + FriendlyProximity + OpponentProximity.

% Find the minimum value in a list or return the default value if the list is empty
default_min_list([], Default, Default).
default_min_list(List, _, Min) :- min_list(List, Min).

% Calculate the proximity of a position to friendly and opponent pieces
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

% Case: Non-negative numbers
abs(X, X) :-
    X >= 0.

% Case: Negative numbers
abs(X, AbsX) :-
    X < 0,
    AbsX is -X.


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

% Calculate the proximity to the center of the board
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
determine_depth(BoardSize, 4) :- BoardSize = 5.  % Medium boards (5x5)
determine_depth(BoardSize, 3) :- BoardSize = 6.  % Medium boards (6x6)
determine_depth(BoardSize, 2) :- BoardSize >= 7.  % Large boards (7x7 and above)