% ai.pl - Contains the AI logic for choosing moves

% choose_move(+GameState, +Difficulty, -Move)
% Choose a move based on the difficulty level
%
% The `choose_move/3` predicate selects a move for the AI player based on the current game state and the specified 
% difficulty level. It follows these steps:
%
% 1. Extract Game State Information:
%    The predicate extracts the `Phase` from the `GameState` structure to determine whether the game is in the setup or 
%    play phase.
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
%      - Difficulty 3: The `minimax/4` predicate is called to select the move that maximizes the long-term value based on 
%        the minimax algorithm with a depth limit of 4.
%
% 5. Print the Selected Move:
%    The `format/2` predicate is used to print the selected move to the console for information purposes.
%
% The `choose_move/3` predicate ensures that the AI selects an appropriate move based on the current game phase and difficulty 
% level, providing a challenging opponent for the player.

% choose_move(+GameState, +Difficulty, -Move)
% Choose a move based on the level
choose_move(GameState, Difficulty, Move) :-
    GameState = state(_, Player, _, Phase, BoardSize),
    valid_moves(GameState, Moves),
    (Phase = setup ->
        random_member(Move, Moves)  % Random move for setup phase
    ;
        % Choose move based on difficulty level
        (Difficulty = 1 ->
            random_member(Move, Moves)  % Random move for level 1
        ; Difficulty = 2 ->
            choose_greedy_move(GameState, Moves, Move)  % Greedy move for level 2
        ; Difficulty = 3 ->
            minimax(GameState, 4, Move, _)  % Minimax move for level 3
        )
    ),
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

% Calculate the value of a move by simulating the move and evaluating the resulting game state
value(GameState, Move, Value) :-
    Move = stack(Y1, X1, Y2, X2),
    move(GameState, stack(Y1, X1, Y2, X2), state(NewBoard, _, _, _, BoardSize)),
    nth1(Y2, NewBoard, Row),
    nth1(X2, Row, Player-NewCount),
    Value is NewCount.

% Choose the best move based on the greedy algorithm
choose_greedy_move(GameState, Moves, BestMove) :-
    findall(Value-Move, (
        member(Move, Moves),
        value(GameState, Move, Value)
    ), MoveValues),
    max_member(_-BestMove, MoveValues).

% Minimax algorithm with depth limit, focusing on maximizing the value and minimizing opponent's advantage
minimax(GameState, Depth, BestMove, BestValue) :-
    Depth > 0,
    valid_moves(GameState, Moves),
    Moves \= [],
    NewDepth is Depth - 1,
    findall(Value-Move, (
        member(Move, Moves),
        move(GameState, Move, NewGameState),
        minimax_value(NewGameState, NewDepth, Value)
    ), MoveValues),
    max_member(BestValue-BestMove, MoveValues).

% Base case: evaluate the game state when depth is 0 or no moves are available
minimax(GameState, 0, _, Value) :-
    evaluate(GameState, Value).

minimax(GameState, _, _, Value) :-
    valid_moves(GameState, Moves),
    Moves = [],
    evaluate(GameState, Value).

% Determine the value for the minimax algorithm
minimax_value(GameState, Depth, Value) :-
    minimax(GameState, Depth, _, Value).

% Evaluate the game state by finding the tallest stack created by the player and minimizing opponent's advantage
evaluate(GameState, Score) :-
    GameState = state(Board, Player, _, _, BoardSize),
    findall(Count, (
        member(Row, Board),
        member(Player-Count, Row)
    ), Counts),
    max_member(TallestStack, Counts),
    opponent(Player, Opponent),
    findall(Distance, (
        member(Row, Board),
        member(Player-Count, Row),
        Count > 0,
        findall(OpponentDistance, (
            member(OpponentRow, Board),
            member(Opponent-OpponentCount, OpponentRow),
            nonvar(Count),
            nonvar(OpponentCount),
            distance(Player-Count, Opponent-OpponentCount, OpponentDistance)
        ), Distances),
        min_list(Distances, Distance)
    ), Distances),
    sumlist(Distances, TotalDistance),
    Score is TallestStack - TotalDistance.

% Calculate the Manhattan distance between two stacks
distance(Player-Count1, Opponent-Count2, Distance) :-
    nonvar(Count1),
    nonvar(Count2),
    abs(Count1 - Count2, Distance).

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
