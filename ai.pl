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
    max_member(BestValue-BestMove, MoveValues),
    format('Depth: ~w, BestMove: ~w, BestValue: ~w~n', [Depth, BestMove, BestValue]).

% Base case: evaluate the game state when depth is 0 or no moves are available
minimax(GameState, 0, _, Value) :-
    evaluate(GameState, Value),
    format('Depth: 0, Value: ~w~n', [Value]).

minimax(GameState, _, _, Value) :-
    valid_moves(GameState, Moves),
    Moves = [],
    evaluate(GameState, Value),
    format('No more valid moves, Value: ~w~n', [Value]).

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
    sum_list(Distances, TotalDistance),
    Score is TallestStack - TotalDistance,
    format('Evaluating GameState: ~w, TallestStack: ~w, TotalDistance: ~w, Score: ~w~n', [GameState, TallestStack, TotalDistance, Score]).

% Calculate the Manhattan distance between two stacks
distance(Player-Count1, Opponent-Count2, Distance) :-
    nonvar(Count1),
    nonvar(Count2),
    abs(Count1 - Count2, Distance),
    format('Distance between ~w and ~w: ~w~n', [Player-Count1, Opponent-Count2, Distance]).

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

% Calculate the sum of elements in a list
sum_list([], 0).
sum_list([H|T], Sum) :-
    sum_list(T, SumTail),
    Sum is H + SumTail.

% Determine the opponent player
opponent(blue, white).
opponent(white, blue).
opponent(blueH, whitePC).
opponent(whitePC, blueH).
opponent(bluePC, whiteH).
opponent(whiteH, bluePC).
opponent(computer1, computer2).
opponent(computer2, computer1).
