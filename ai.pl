% ai.pl - Contains the AI logic for choosing moves

% choose_move(+GameState, +Difficulty, -Move).
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

% Evaluate the game state by finding the tallest stack created by the player
evaluate(GameState, Score) :-
    GameState = state(Board, Player, _, _, BoardSize),
    findall(Count, (
        member(Row, Board),
        member(Player-Count, Row)
    ), Counts),
    max_member(Score, Counts).

% Minimax algorithm with depth limit, focusing only on maximizing the value
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

