% ai.pl - Contains the AI logic for choosing moves

% Choose a move based on the level
choose_move(GameState, Difficulty, Move) :-
    GameState = state(_, Player, _, Phase),
    format('Debug: Choosing move for ~w with difficulty ~w~n', [Player, Difficulty]),
    valid_moves(GameState, Moves),
    format('Debug: Valid moves for computer: ~w~n', [Moves]),
    (Phase = setup ->
        format('Debug: Doing random setup~n', []),
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

% Calculate the value of a game state by finding the tallest stack created by the player
value(state(Board, Player, _, _), Player, Value) :-
    findall(Count, (
        member(Row, Board),
        member(Player-Count, Row)
    ), Counts),
    format('Debug: Player ~w stack counts: ~w~n', [Player, Counts]),
    max_member(Value, Counts).

% Calculate the value of a move by simulating the move and evaluating the resulting game state
move_value(GameState, stack(Y1, X1, Y2, X2), Value) :-
    move(GameState, stack(Y1, X1, Y2, X2), state(NewBoard, _, _, _)),
    nth1(Y2, NewBoard, Row),
    nth1(X2, Row, Player-NewCount),
    Value is NewCount.

% Choose the best move based on the greedy algorithm
choose_greedy_move(GameState, Moves, BestMove) :-
    format('Debug: Entering choose_greedy_move~n', []),
    findall(Value-Move, (
        member(Move, Moves),
        move_value(GameState, Move, Value)
    ), MoveValues),
    format('Debug: Move values: ~w~n', [MoveValues]),
    max_member(_-BestMove, MoveValues).

% Evaluate the game state by finding the tallest stack created by the player
evaluate(state(Board, Player, _, _), Score) :-
    findall(Count, (
        member(Row, Board),
        member(Player-Count, Row)
    ), Counts),
    max_member(Score, Counts).

% Minimax algorithm with depth limit, focusing only on maximizing the value
minimax(GameState, Depth, BestMove, BestValue) :-
    format('Debug: Entering minimax with Depth ~w~n', [Depth]),
    Depth > 0,
    valid_moves(GameState, Moves),
    Moves \= [],
    format('Debug: Valid moves: ~w~n', [Moves]),
    NewDepth is Depth - 1,
    findall(Value-Move, (
        member(Move, Moves),
        format('Debug: Simulating move: ~w~n', [Move]),
        move(GameState, Move, NewGameState),
        minimax_value(NewGameState, NewDepth, Value),
        format('Debug: Move ~w has value ~w~n', [Move, Value])
    ), MoveValues),
    format('Debug: Move values: ~w~n', [MoveValues]),
    max_member(BestValue-BestMove, MoveValues),
    format('Debug: Choosing move: ~w with value: ~w~n', [BestMove, BestValue]).

% Base case: evaluate the game state when depth is 0 or no moves are available
minimax(GameState, 0, _, Value) :-
    format('Debug: Base case reached with Depth 0~n', []),
    evaluate(GameState, Value),
    format('Debug: Evaluated value: ~w~n', [Value]).
minimax(GameState, _, _, Value) :-
    format('Debug: Base case reached with no valid moves~n', []),
    valid_moves(GameState, Moves),
    Moves = [],
    evaluate(GameState, Value),
    format('Debug: Evaluated value: ~w~n', [Value]).

% Determine the value for the minimax algorithm
minimax_value(GameState, Depth, Value) :-
    minimax(GameState, Depth, _, Value).

