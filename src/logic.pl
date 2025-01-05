% logic.pl - Contains the game logic and rules

get_player_move(GameState, Difficulty1, Difficulty2, Move) :-
    GameState = state(_, Player, _, _, _),
    valid_moves(GameState, Moves),
    get_move(GameState, Player, Moves, Difficulty1, Difficulty2, Move).

% Case: No valid moves, skip the turn
get_move(_, Player, [], _, _, skip) :-
    format('Player ~w has no valid moves and will skip their turn.~n', [Player]).

% Case: Computer player chooses a move based on difficulty
get_move(GameState, whitePC, _, Difficulty1, _, Move) :- choose_move(GameState, Difficulty1, Move).
get_move(GameState, bluePC, _, Difficulty1, _, Move) :- choose_move(GameState, Difficulty1, Move).
get_move(GameState, computer1, _, Difficulty1, _, Move) :- choose_move(GameState, Difficulty1, Move).
get_move(GameState, computer2, _, _, Difficulty2, Move) :- choose_move(GameState, Difficulty2, Move).

% Case: Human player enters a move
get_move(GameState, Player, Moves, _, _, Move) :-
    format('Enter your move (e.g., place(X, Y) or stack(X1, Y1, X2, Y2)/skip): ~n', []),
    prompt(_, 'Move: '),
    read(InputMove),
    prompt(_, '|: '),  % Reset the prompt to the default
    validate_human_move(GameState, InputMove, Moves, Player, Move).

% Validate the move entered by the human player
validate_human_move(GameState, InputMove, Moves, _, InputMove) :-
    member(InputMove, Moves).
validate_human_move(GameState, _, Moves, Player, Move) :-
    format('Invalid move! Try again.~n', []),
    get_move(GameState, Player, Moves, _, _, Move).


% Check if the move is valid in the setup phase
valid_move(GameState, Move) :-
    GameState = state(Board, Player, Pieces, setup, BoardSize),
    Move = place(Y, X),
    X > 0, X =< BoardSize,  % Check if X is within board boundaries
    Y > 0, Y =< BoardSize,  % Check if Y is within board boundaries
    nth1(Y, Board, Row), nth1(X, Row, Cell),
    Cell = n-1.  % The cell is neutral with a stack size of 1

% Check if the move is valid in the play phase
valid_move(GameState, Move) :-
    GameState = state(Board, Player, _, play, BoardSize),
    Move = stack(Y1, X1, Y2, X2),
    % Ensure coordinates are valid
    X1 > 0, X1 =< BoardSize, Y1 > 0, Y1 =< BoardSize,
    X2 > 0, X2 =< BoardSize, Y2 > 0, Y2 =< BoardSize,
    (X1 =:= X2 ; Y1 =:= Y2), % Must move orthogonally
    abs(X1 - X2) + abs(Y1 - Y2) =:= 1, % Ensure the move is exactly one cell
    nth1(Y1, Board, Row1), nth1(X1, Row1, SourceStack),
    nth1(Y2, Board, Row2), nth1(X2, Row2, DestCell),
    SourceStack = Player-Count, Count > 0, % Source must belong to current player
    (DestCell = n-1 ; DestCell = Player-_). % Destination must be neutral or belong to the player

% Check if the move is valid
valid_move(state(_, _, _, play, _), skip).

% move(+GameState, +Move, -NewGameState)
% Apply the move to the game state and return the new state
%
% The `move/3` predicate updates the game state based on the player's move. It handles different types of moves and transitions 
% the game state accordingly. It follows these steps:
%
% 1. Skip Move:
%    - If the move is `skip`, the current player skips their turn.
%    - The `next_player/2` predicate is called to switch to the next player.
%    - The game state is updated with the same board and pieces, but with the next player.
%
% 2. Place Move (Setup Phase):
%    - If the move is `place(Y, X)`, the current player places a piece on the board during the setup phase.
%    - The `place_piece/4` predicate is called to place the piece on the board.
%    - The `next_player/2` predicate is called to switch to the next player.
%    - The `update_pieces/4` predicate is called to update the number of remaining pieces for the current player.
%    - If all pieces are placed, the game phase transitions to `play`; otherwise, it remains in `setup`.
%
% 3. Stack Move (Play Phase):
%    - If the move is `stack(Y1, X1, Y2, X2)`, the current player stacks a piece from one cell to an adjacent cell during the 
%      play phase.
%    - The `stack_piece/5` predicate is called to stack the piece on the board.
%    - The `next_player/2` predicate is called to switch to the next player.
%    - The `update_pieces/4` predicate is called, but the number of pieces does not change during the play phase.
%
% The `move/3` predicate ensures that the game state is updated correctly based on the player's move, maintaining the integrity of 
% the game logic.

% Skip Move
move(GameState, Move, NewGameState) :-
    GameState = state(Board, Player, Pieces, play, BoardSize),
    Move = skip,
    NewGameState = state(Board, NextPlayer, Pieces, play, BoardSize),
    next_player(Player, NextPlayer).

% Place Move (Setup Phase)
move(GameState, Move, NewGameState) :-
    GameState = state(Board, Player, Pieces, setup, BoardSize),
    Move = place(Y, X),
    NewGameState = state(NewBoard, NextPlayer, NewPieces, NewPhase, BoardSize),
    place_piece(Board, X, Y, Player, NewBoard),
    next_player(Player, NextPlayer),
    update_pieces(Player, Pieces, NewPieces, setup),
    determine_phase(NewPieces, NewPhase).

% Helper predicate to determine the next phase based on remaining pieces
determine_phase([Player1-0, Player2-0], play).
determine_phase(_, setup).


% Stack Move (Play Phase)
move(GameState, Move, NewGameState) :-
    GameState = state(Board, Player, Pieces, play, BoardSize),
    Move = stack(Y1, X1, Y2, X2),
    NewGameState = state(NewBoard, NextPlayer, NewPieces, play, BoardSize),
    stack_piece(Board, X1, Y1, X2, Y2, NewBoard),
    next_player(Player, NextPlayer),
    update_pieces(Player, Pieces, NewPieces, play).  % Do not decrement pieces during the play phase
    
% Place a piece on a neutral cell
place_piece(Board, X, Y, Player, NewBoard) :-
    nth1(Y, Board, Row),
    nth1(X, Row, n-1),  % Match neutral cell
    NewCell = Player-2, % Add the player's piece
    replace_element(Row, X, NewCell, NewRow),
    replace_board(Board, Y, NewRow, NewBoard).

% Place a piece on a cell that already belongs to the player
place_piece(Board, X, Y, Player, NewBoard) :-
    nth1(Y, Board, Row),
    nth1(X, Row, Player-Count),  % Match player's cell
    NewCell = Player-(Count+1),  % Increment the count
    replace_element(Row, X, NewCell, NewRow),
    replace_board(Board, Y, NewRow, NewBoard).

% Fail if the cell is occupied by an opponent
place_piece(Board, X, Y, _, _) :-
    nth1(Y, Board, Row),
    nth1(X, Row, Cell),
    Cell \= n-1,  % Ensure the cell is not neutral
    Cell \= Player-_,  % Ensure the cell does not belong to the player
    format('Invalid move: cell already occupied by opponent.~n'),
    fail.


% Stack a piece on top of another
stack_piece(Board, X1, Y1, X2, Y2, NewBoard) :-
    nth1(Y1, Board, SourceRow),
    nth1(X1, SourceRow, SourceStack),
    nth1(Y2, Board, DestRow),
    nth1(X2, DestRow, DestStack),
    calculate_new_stack(SourceStack, DestStack, NewStack),
    (Y1 =:= Y2 ->  % If the source and destination are in the same row (can't remove this if otherwise performance drops significantly)
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

% game_over(+GameState, -Winner)
% Check if the game is over and return the winner
%
% The `game_over/2` predicate determines if the game has ended and identifies the winner. It follows these steps:
%
% 1. Extract Game State Information:
%    The predicate extracts the `Board`, `Player`, `Pieces`, and `BoardSize` from the `GameState` structure. This information 
%    is used to check the game-over conditions.
%
% 2. Check for No More Moves:
%    The predicate checks if there are no more valid moves for both players. This is done by calling the `no_more_moves/1` 
%    predicate for each player (`Player1` and `Player2`). If both players have no valid moves left, the game is considered over.
%
% 3. Determine the Winner:
%    If the game is over, the `tallest_stack/3` predicate is called to determine the winner based on the tallest stack on the 
%    board. The `tallest_stack/3` predicate finds the player with the tallest stack and assigns them as the winner.
%
% The `game_over/2` predicate ensures that the game ends correctly when no more valid moves are available for both players 
% and identifies the winner based on the tallest stack.

% game_over(+GameState, -Winner)
% Check if the game is over and return the winner
game_over(GameState, Winner) :-
    GameState = state(Board, Player, Pieces, play, BoardSize),
    Pieces = [Player1-_, Player2-_],
    no_more_moves(state(Board, Player1, _, play, BoardSize)),
    no_more_moves(state(Board, Player2, _, play, BoardSize)),
    tallest_stack(Board, Winner, TallestStack).

% Find the tallest stack, the winner, and the stack size
tallest_stack(Board, Winner, TallestStack) :-
    findall(Count-Player, (member(Row, Board), member(Player-Count, Row), Player \= n), CountsPlayers),
    sort(CountsPlayers, SortedCountsPlayers),
    reverse(SortedCountsPlayers, DescendingCountsPlayers),
    determine_winner(DescendingCountsPlayers, Winner, TallestStack).

% Case: Two or more stacks, and the tallest two are equal
determine_winner([Count1-Player1, Count2-Player2 | Rest], Winner, TallestStack) :-
    counts_equal(Count1, Count2),
    determine_winner(Rest, Winner, TallestStack).

% Case: Two or more stacks, and the tallest stack is unique
determine_winner([Count1-Player1, Count2-Player2 | _], Player1, Count1) :-
    counts_not_equal(Count1, Count2).

% Case: Only one stack remains
determine_winner([Count-Player | _], Player, Count).

% Case: No valid stacks
determine_winner([], no_winner, 0).

% Helper predicate to check if two counts are equal
counts_equal(Count, Count).

% Helper predicate to check if two counts are not equal
counts_not_equal(Count1, Count2) :-
    Count1 \= Count2.

% Check if there are no more valid moves
no_more_moves(state(Board, Player, Pieces, Phase, BoardSize)) :-
    Phase = play,  % Ensure this is only checked during the play phase
    valid_moves(state(Board, Player, Pieces, Phase, BoardSize), Moves),
    Moves = [].

% valid_moves(+GameState, -Moves)
% Find all valid moves for a player in the setup phase
%
% The `valid_moves/2` predicate generates a list of all valid moves for the current player based on the game state. It handles 
% both the setup and play phases of the game. It follows these steps:
%
% 1. Setup Phase:
%    - The predicate checks if the game is in the `setup` phase by matching the `Phase` in the `GameState` structure.
%    - It uses the `findall/3` predicate to collect all valid `place(Y, X)` moves. These moves represent placing a piece on the
%      board at coordinates `(Y, X)`.
%    - The `between/3` predicate is used to iterate over all possible positions on the board, from `1` to `BoardSize` for both 
%      `Y` and `X`.
%    - For each position, the `valid_move/2` predicate is called to check if placing a piece at that position is valid. If it 
%      is valid, the move is included in the `Moves` list.
%
% 2. Play Phase:
%    - The predicate checks if the game is in the `play` phase by matching the `Phase` in the `GameState` structure.
%    - It uses the `findall/3` predicate to collect all valid `stack(Y1, X1, Y2, X2)` moves. These moves represent stacking a 
%      piece from coordinates `(Y1, X1)` to an adjacent cell `(Y2, X2)`.
%    - The `between/3` predicate is used to iterate over all possible source and destination positions on the board, from `1` to `
%      BoardSize` for both `Y1`, `X1`, `Y2`, and `X2`.
%    - For each pair of source and destination positions, the `valid_move/2` predicate is called to check if stacking a piece 
%      from the source to the destination is valid. If it is valid, the move is included in the `Moves` list.
%
% The `valid_moves/2` predicate ensures that all possible valid moves for the current player are generated, providing a 
% comprehensive list of options for the player to choose from.

% Find all valid moves for a player in the setup phase
valid_moves(GameState, Moves) :-
    GameState = state(Board, Player, Pieces, setup, BoardSize),
    findall(place(Y, X), (
        between(1, BoardSize, Y), between(1, BoardSize, X), % Iterate over all positions
        valid_move(state(Board, Player, Pieces, setup, BoardSize), place(Y, X))
    ), Moves).

% Find all valid moves for a player in the play phase
valid_moves(GameState, Moves) :-
    GameState = state(Board, Player, Pieces, play, BoardSize),
    findall(stack(Y1, X1, Y2, X2), (
        between(1, BoardSize, Y1), between(1, BoardSize, X1), % Iterate over source positions
        between(1, BoardSize, Y2), between(1, BoardSize, X2), % Iterate over destination positions
        valid_move(state(Board, Player, Pieces, play, BoardSize), stack(Y1, X1, Y2, X2))
    ), Moves).

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
