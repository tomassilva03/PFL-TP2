% logic.pl - Contains the game logic and rules

% Get the player's move
get_player_move(GameState, Difficulty1, Difficulty2, Move) :-
    GameState = state(_, Player, _, Phase),
    valid_moves(GameState, Moves),
    (Moves = [] ->
        % No moves available, skip the turn
        format('Player ~w has no valid moves and will skip their turn.~n', [Player]),
        Move = skip
    ; (Player = whitePC ->
        choose_move(GameState, Difficulty1, Move)
    ; Player = bluePC ->
        choose_move(GameState, Difficulty1, Move)
    ; Player = computer1 ->
        choose_move(GameState, Difficulty1, Move)
    ; Player = computer2 ->
        choose_move(GameState, Difficulty2, Move)
    ; % Otherwise, prompt the human player for input
        format('Enter your move, X = row, Y = column (e.g., place(X,Y) or stack(X,Y,A,B)): ~n', []),
        read(InputMove),
        (valid_move(GameState, InputMove) ->
            Move = InputMove
        ; format('Invalid move! Try again.~n', []),
          get_player_move(GameState, Difficulty1, Difficulty2, Move)
        )
    )).

% Check if the move is valid in the setup phase
valid_move(state(Board, Player, Pieces, setup), place(Y, X)) :-
    X > 0, X =< 5,  % Check if X is within board boundaries
    Y > 0, Y =< 5,  % Check if Y is within board boundaries
    nth1(Y, Board, Row), nth1(X, Row, Cell),
    Cell = n-1.  % The cell is neutral with a stack size of 1

% Check if the move is valid in the play phase
valid_move(state(Board, Player, _, play), stack(Y1, X1, Y2, X2)) :-
    % Ensure coordinates are valid
    X1 > 0, X1 =< 5, Y1 > 0, Y1 =< 5,
    X2 > 0, X2 =< 5, Y2 > 0, Y2 =< 5,
    (X1 =:= X2 ; Y1 =:= Y2), % Must move orthogonally
    abs(X1 - X2) + abs(Y1 - Y2) =:= 1, % Ensure the move is exactly one cell
    nth1(Y1, Board, Row1), nth1(X1, Row1, SourceStack),
    nth1(Y2, Board, Row2), nth1(X2, Row2, DestCell),
    SourceStack = Player-Count, Count > 0, % Source must belong to current player
    (DestCell = n-1 ; DestCell = Player-_). % Destination must be neutral or belong to the player

% Check if the move is valid
valid_move(state(_, _, _, play), skip).

% Apply the move to the game state and return the new state
move(state(Board, Player, Pieces, play), skip, state(Board, NextPlayer, Pieces, play)) :-
    next_player(Player, NextPlayer).

% Apply the move to the game state and return the new state
move(state(Board, Player, Pieces, setup), place(Y, X), state(NewBoard, NextPlayer, NewPieces, NewPhase)) :-
    place_piece(Board, X, Y, Player, NewBoard),
    next_player(Player, NextPlayer),
    update_pieces(Player, Pieces, NewPieces, setup),
    (NewPieces = [Player1-0, Player2-0] -> NewPhase = play ; NewPhase = setup).  % Transition to play phase if all pieces are placed

% Apply the move to the game state and return the new state
move(state(Board, Player, Pieces, play), stack(Y1, X1, Y2, X2), state(NewBoard, NextPlayer, NewPieces, play)) :-
    stack_piece(Board, X1, Y1, X2, Y2, NewBoard),
    next_player(Player, NextPlayer),
    update_pieces(Player, Pieces, NewPieces, play).  % Do not decrement pieces during the play phase

% Place a piece on the board
place_piece(Board, X, Y, Player, NewBoard) :-
    nth1(Y, Board, Row),
    nth1(X, Row, Cell),
    ( Cell = n-1 ->  % If the cell is neutral
        NewCell = Player-2  % Add the player's piece on top of the neutral piece
    ; Cell = Player-Count ->  % If the cell already belongs to the player
        NewCell = Player-(Count+1)  % Increment the count
    ; format('Invalid move: cell already occupied by opponent.~n'), fail  % Cell occupied by the opponent
    ),
    replace_element(Row, X, NewCell, NewRow),
    replace_board(Board, Y, NewRow, NewBoard).

% Stack a piece on top of another
stack_piece(Board, X1, Y1, X2, Y2, NewBoard) :-
    nth1(Y1, Board, SourceRow),
    nth1(X1, SourceRow, SourceStack),
    nth1(Y2, Board, DestRow),
    nth1(X2, DestRow, DestStack),
    calculate_new_stack(SourceStack, DestStack, NewStack),
    (Y1 =:= Y2 ->  % If the source and destination are in the same row
        replace_element(SourceRow, X1, e-0, TempRow),  % Update source cell
        replace_element(TempRow, X2, NewStack, UpdatedRow),  % Update destination cell
        replace_board(Board, Y1, UpdatedRow, NewBoard)  % Replace the updated row
    ; % Source and destination are in different rows
        replace_element(SourceRow, X1, e-0, UpdatedSourceRow),
        replace_element(DestRow, X2, NewStack, UpdatedDestRow),
        replace_board(Board, Y1, UpdatedSourceRow, TempBoard),
        replace_board(TempBoard, Y2, UpdatedDestRow, NewBoard)
    ).

% Switch between players
% For blue vs white
next_player(white, blue).
next_player(blue, white).

% For blue vs computer
next_player(whitePC, blueH).
next_player(blueH, whitePC).

% For computer vs white
next_player(whiteH, bluePC).
next_player(bluePC, whiteH).

% For computer vs computer
next_player(computer1, computer2).
next_player(computer2, computer1).

% Update the pieces remaining for each player during the setup phase
update_pieces(Player1, [Player1-N, Player2-M], [Player1-N1, Player2-M], setup) :-
    N1 is N - 1.
update_pieces(Player2, [Player1-N, Player2-M], [Player1-N, Player2-M1], setup) :-
    M1 is M - 1.
update_pieces(_, Pieces, Pieces, play).  % Do not decrement pieces during the play phase

% Check if the game is over
game_over(state(Board, Player, Pieces, play), Winner) :-
    Pieces = [Player1-_, Player2-_],
    no_more_moves(state(Board, Player1, _, play)),
    no_more_moves(state(Board, Player2, _, play)),
    tallest_stack(Board, Winner).

% Check if there are no more valid moves
no_more_moves(state(Board, Player, Pieces, Phase)) :-
    Phase = play,  % Ensure this is only checked during the play phase
    valid_moves(state(Board, Player, Pieces, Phase), Moves),
    Moves = [].

% Find all valid moves for a player in the setup phase
valid_moves(state(Board, Player, Pieces, setup), Moves) :-
    findall(place(Y, X), (
        between(1, 5, Y), between(1, 5, X), % Iterate over all positions
        valid_move(state(Board, Player, Pieces, setup), place(Y, X))
    ), Moves).

% Find all valid moves for a player in the play phase
valid_moves(state(Board, Player, Pieces, play), Moves) :-
    findall(stack(Y1, X1, Y2, X2), (
        between(1, 5, Y1), between(1, 5, X1), % Iterate over source positions
        between(1, 5, Y2), between(1, 5, X2), % Iterate over destination positions
        valid_move(state(Board, Player, Pieces, play), stack(Y1, X1, Y2, X2))
    ), Moves).

% Determine the player with the tallest stack
tallest_stack(Board, Winner) :-
    findall(Count-Player, (member(Row, Board), member(Player-Count, Row), Player \= n), CountsPlayers),
    sort(CountsPlayers, SortedCountsPlayers),
    reverse(SortedCountsPlayers, DescendingCountsPlayers),
    DescendingCountsPlayers = [MaxCount-Player1, SecondMaxCount-Player2, ThirdMaxCount-Player3 | _],
    (MaxCount =:= SecondMaxCount ->
        Winner = Player3
    ;
        Winner = Player1
    ).

% Correctly replace an element in a list
replace_element([_|T], 1, Elem, [Elem|T]).
replace_element([H|T], Index, Elem, [H|T2]) :-
    Index > 1,
    NewIndex is Index - 1,
    replace_element(T, NewIndex, Elem, T2).

% Correctly replace a row in the board
replace_board([Row|T], 1, NewRow, [NewRow|T]).
replace_board([H|T], Index, NewRow, [H|T2]) :-
    Index > 1,
    NewIndex is Index - 1,
    replace_board(T, NewIndex, NewRow, T2).

% If both source and destination are player stacks of the same type
calculate_new_stack(Player-SourceCount, Player-DestCount, Player-NewCount) :-
    NewCount is SourceCount + DestCount.

% If source is player stack and destination is neutral
calculate_new_stack(Player-SourceCount, n-1, Player-NewCount) :-
    NewCount is SourceCount + 1.
    