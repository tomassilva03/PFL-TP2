% ['/Users/tomassilva/pfl-prolog-project/game.pl'].  % Load the game file

:- use_module(library(lists)).
:- use_module(library(between)).
:- use_module(library(plunit)).
:- use_module(library(random)).


% Display the game menu and start the game
play :-
    display_menu,
    read(GameType),
    configure_game(GameType, GameConfig),
    initial_state(GameConfig, GameState),
    game_loop(GameState).

% Display the game menu
display_menu :-
    format('Welcome to the Game!~n', []),
    format('Select game type:~n', []),
    format('1. Human vs Human (H/H)~n', []),
    format('2. Human vs Computer (H/PC)~n', []),
    format('3. Computer vs Human (PC/H)~n', []),
    format('4. Computer vs Computer (PC/PC)~n', []),
    format('Enter your choice (1-4): ', []).

% Configure the game based on the selected game type
configure_game(1, [board_size(5), player1(blue), player2(white), optional_rules([]), player1_name('Player 1'), player2_name('Player 2')]) :-
    format('Starting Human vs Human game...~n', []).
configure_game(2, [board_size(5), player1(blue), player2(computer), difficulty(Level), optional_rules([]), player1_name('Player 1'), player2_name('Computer')]) :-
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Level),
    format('Starting Human vs Computer game with difficulty level ~w...~n', [Level]).
configure_game(3, [board_size(5), player1(computer), player2(white), optional_rules([]), player1_name('Computer'), player2_name('Player 2')]) :-
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Difficulty),
    format('Starting Computer vs Human game with difficulty level ~w...~n', [Difficulty]).
configure_game(4, [board_size(5), player1(computer1), player2(computer2), optional_rules([]), player1_name('Computer 1'), player2_name('Computer 2')]) :-
    format('Select difficulty level for Computer 1:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Difficulty1),
    format('Select difficulty level for Computer 2:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Difficulty2),
    format('Starting Computer vs Computer game with difficulty levels ~w and ~w...~n', [Difficulty1, Difficulty2]).

% Main game loop
game_loop(GameState) :-
    display_game(GameState),
    ( game_over(GameState, Winner) ->
        format('Game over! Winner: ~w~n', [Winner])
    ; get_player_move(GameState, Move),
      (Move = exit ->
          format('Exiting game.~n', []),
          halt
      ; move(GameState, Move, NewGameState),
        game_loop(NewGameState) ) ).

% initial_state(+GameConfig, -GameState)
% Sets up the initial game state based on the provided configuration.
initial_state(GameConfig, state(Board, CurrentPlayer, Pieces, Phase)) :-
    % Extract configuration parameters
    ( member(board_size(BoardSize), GameConfig) -> true ; BoardSize = 5 ),
    ( member(player1(Player1), GameConfig) -> true ; Player1 = blue ),
    ( member(player2(Player2), GameConfig) -> true ; Player2 = white ),
    ( member(optional_rules(OptionalRules), GameConfig) -> true ; OptionalRules = [] ),
    ( member(player1_name(Player1Name), GameConfig) -> true ; Player1Name = 'Player 1' ),
    ( member(player2_name(Player2Name), GameConfig) -> true ; Player2Name = 'Player 2' ),
    ( member(difficulty(Level), GameConfig) -> true ; Level = 1 ),
    
    % Initialize the board based on the board size
    initialize_board(BoardSize, Board),
    
    % Set the initial player
    CurrentPlayer = Player1,
    
    % Set the initial pieces for each player
    Pieces = [blue-4, white-4], % Ensure this format is used regardless of Player2 being a computer or human
    
    % Set the initial phase
    Phase = setup,
    
    % Print the game configuration for debugging
    format('Game configuration:~n', []),
    format('Board size: ~w~n', [BoardSize]),
    format('Player 1: ~w (~w)~n', [Player1, Player1Name]),
    format('Player 2: ~w (~w)~n', [Player2, Player2Name]),
    format('Optional rules: ~w~n', [OptionalRules]).


% Initialize the board based on the board size
initialize_board(BoardSize, Board) :-
    length(Board, BoardSize),
    maplist(initialize_row(BoardSize), Board).

% Initialize a row with neutral pieces
initialize_row(BoardSize, Row) :-
    length(Row, BoardSize),
    maplist(=(n-1), Row).

% Display the game state
display_game(state(Board, Player, Pieces, Phase)) :-
    format('Debug: Entering display_game~n', []),
    (print_board(Board) -> 
        format('Debug: Finished printing board~n', [])
    ; 
        format('Debug: Failed to print board~n', []), fail
    ),
    format('Debug: About to format current player~n', []),
    format('Current player: ~w~n', [Player]),
    format('Debug: About to format pieces~n', []),
    (format_pieces(Pieces) ->
        format('Debug: Finished formatting pieces~n', [])
    ;
        format('Debug: Failed to format pieces~n', []), fail
    ),
    format('Debug: About to format phase~n', []),
    format('Current phase: ~w~n', [Phase]),
    format('Debug: Exiting display_game~n', []).

% Print the entire board with borders
print_board(Board) :-
    write('  |     1     |     2     |     3     |     4     |     5     |'), nl,  % Column headers
    write('--+-----------+-----------+-----------+-----------+-----------+'), nl,
    print_board_rows(Board, 1).  % Start printing rows with indices

% Print each row with borders and row indices
print_board_rows([], _).
print_board_rows([Row|Rest], RowIndex) :-
    format('~d |', [RowIndex]),  % Row index
    print_row(Row), nl,
    write('--+-----------+-----------+-----------+-----------+-----------+'), nl,  % Row border
    NextRowIndex is RowIndex + 1,
    print_board_rows(Rest, NextRowIndex).

% Print a single row with vertical dividers
print_row([]).
print_row([Cell|Rest]) :-
    write_piece(Cell),
    write('|'),
    print_row(Rest).

% Write a piece or stack with fixed width for all cells
write_piece(n-1) :- write(' neutral-1 '). 
write_piece(e-0) :- write('  empty-0  '). 
write_piece(blue-Count) :- format('   blue-~d  ', [Count]).
write_piece(white-Count) :- format('  white-~d  ', [Count]).

% Display Pieces in proper format
format_pieces([blue-N, white-M]) :-
    format('Debug: In format_pieces with blue = ~w and white = ~w~n', [N, M]),
    format('blue: ~d pieces, white: ~d pieces~n', [N, M]).
format_pieces(Pieces) :-
    format('Error: Invalid Pieces list: ~w~n', [Pieces]),
    fail.

% Get the player's move
get_player_move(state(_, Player, _, _), Move) :-
    (Player = computer ->
        % Generate a move for the computer based on difficulty
        choose_move(state(_, Player, _, _), Move)
    ; % Otherwise, prompt the human player for input
        format('Enter your move, X = row, Y = column (e.g., place(X,Y) or stack(X,Y,A,B)): ~n', []),
        read(InputMove),
        (InputMove = exit ->
            Move = exit
        ; valid_move(state(_, Player, _, _), InputMove) ->
            Move = InputMove
        ; format('Invalid move! Try again.~n', []),
          get_player_move(state(_, Player, _, _), Move)
        )
    ).


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
    format('Player ~w skips their turn~n', [Player]),
    next_player(Player, NextPlayer).

% Apply the move to the game state and return the new state
move(state(Board, Player, Pieces, setup), place(Y, X), state(NewBoard, NextPlayer, NewPieces, NewPhase)) :-
    format('Applying move place(~w, ~w) for player ~w~n', [Y, X, Player]),
    place_piece(Board, X, Y, Player, NewBoard),
    next_player(Player, NextPlayer),
    update_pieces(Player, Pieces, NewPieces, setup),
    (NewPieces = [blue-0, white-0] -> NewPhase = play ; NewPhase = setup).  % Transition to play phase if all pieces are placed

% Apply the move to the game state and return the new state
move(state(Board, Player, Pieces, play), stack(Y1, X1, Y2, X2), state(NewBoard, NextPlayer, NewPieces, play)) :-
    format('Applying move stack(~w, ~w, ~w, ~w) for player ~w~n', [Y1, X1, Y2, X2, Player]),
    stack_piece(Board, X1, Y1, X2, Y2, NewBoard),
    next_player(Player, NextPlayer),
    update_pieces(Player, Pieces, NewPieces, play).  % Do not decrement pieces during the play phase

% Place a piece on the board
place_piece(Board, X, Y, Player, NewBoard) :-
    format('Placing piece for player ~w at (~w, ~w)~n', [Player, Y, X]),
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
    format('Stacking piece from (~w, ~w) to (~w, ~w)~n', [Y1, X1, Y2, X2]),
    nth1(Y1, Board, SourceRow),
    nth1(X1, SourceRow, SourceStack),
    nth1(Y2, Board, DestRow),
    nth1(X2, DestRow, DestStack),
    calculate_new_stack(SourceStack, DestStack, NewStack),
    format('Source stack at (~w, ~w): ~w~n', [Y1, X1, SourceStack]),
    format('Destination stack at (~w, ~w): ~w~n', [Y2, X2, DestStack]),
    format('New stack at destination: ~w~n', [NewStack]),
    (Y1 =:= Y2 ->  % If the source and destination are in the same row
        replace_element(SourceRow, X1, e-0, TempRow),  % Update source cell
        replace_element(TempRow, X2, NewStack, UpdatedRow),  % Update destination cell
        replace_board(Board, Y1, UpdatedRow, NewBoard)  % Replace the updated row
    ; % Source and destination are in different rows
        replace_element(SourceRow, X1, e-0, UpdatedSourceRow),
        replace_element(DestRow, X2, NewStack, UpdatedDestRow),
        replace_board(Board, Y1, UpdatedSourceRow, TempBoard),
        replace_board(TempBoard, Y2, UpdatedDestRow, NewBoard)
    ),
    format('Final updated board: ~w~n', [NewBoard]).

% Switch between players
next_player(blue, white).
next_player(white, blue).

% Update the pieces remaining for each player during the setup phase
update_pieces(blue, [blue-N, white-M], [blue-N1, white-M], setup) :-
    N1 is N - 1.
update_pieces(white, [blue-N, white-M], [blue-N, white-M1], setup) :-
    M1 is M - 1.
update_pieces(_, Pieces, Pieces, play).  % Do not decrement pieces during the play phase

% Check if the game is over
game_over(state(Board, _, _, play), Winner) :-
    format('Checking game over condition...~n', []),
    no_more_moves(state(Board, blue, _, play)),
    no_more_moves(state(Board, white, _, play)),
    tallest_stack(Board, Winner).

% Check if there are no more valid moves
no_more_moves(state(Board, Player, Pieces, Phase)) :-
    Phase = play,  % Ensure this is only checked during the play phase
    valid_moves(state(Board, Player, Pieces, Phase), Moves),
    format('Valid moves for player ~w: ~w~n', [Player, Moves]),
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
    max_member(MaxCount-Player, CountsPlayers),
    Winner = Player.

% Check if a player has stacked 3 pieces in a row
check_win_condition(Board, Player) :-
    no_more_moves(state(Board, Player, _, play)).

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
    NewCount is SourceCount + DestCount,
    format('Combining player stacks. New stack: ~w~n', [Player-NewCount]).

% If source is player stack and destination is neutral
calculate_new_stack(Player-SourceCount, n-1, Player-NewCount) :-
    NewCount is SourceCount + 1,
    format('Adding to neutral stack. New stack: ~w~n', [Player-NewCount]).

% Choose a move based on the level
choose_move(state(_, computer, _, _), Move) :-
    % Example for random difficulty (Level 1)
    valid_moves(state(_, computer, _, _), Moves),
    random_member(Move, Moves). % Pick a random move from valid ones

% Tests
:- begin_tests(game_tests).

test(configure_game_human_vs_human) :-
    configure_game(1, Config),
    Config = [board_size(5), player1(blue), player2(white), optional_rules([]), player1_name('Player 1'), player2_name('Player 2')].

test(configure_game_human_vs_computer) :-
    with_input_from(string("2\n1\n"), configure_game(2, Config)),
    Config = [board_size(5), player1(blue), player2(computer), optional_rules([]), player1_name('Player 1'), player2_name('Computer')].

test(configure_game_computer_vs_human) :-
    with_input_from(string("3\n2\n"), configure_game(3, Config)),
    Config = [board_size(5), player1(computer), player2(white), optional_rules([]), player1_name('Computer'), player2_name('Player 2')].

test(configure_game_computer_vs_computer) :-
    with_input_from(string("4\n3\n2\n"), configure_game(4, Config)),
    Config = [board_size(5), player1(computer1), player2(computer2), optional_rules([]), player1_name('Computer 1'), player2_name('Computer 2')].

% Test: The game should not end if valid moves exist
test(game_not_ended_with_valid_moves) :-
    GameState = state([[blue-7, n-1, e-0, e-0, white-5],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, blue-2, e-0, white-3],
                       [e-0, e-0, e-0, blue-2, e-0],
                       [white-4, e-0, e-0, e-0, blue-2]], blue, [blue-0, white-0], play),
    \+ game_over(GameState, _), % Assert that the game is not over
    valid_moves(GameState, Moves), % Collect all valid moves
    format('Valid moves: ~w~n', [Moves]). % Debugging output

% Test: The game should end if no more valid moves exist and a winner is determined
test(game_ended_with_no_valid_moves_and_winner_blue) :-
    GameState = state([[blue-7, e-0, e-0, e-0, white-5],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, blue-2, e-0, white-3],
                       [e-0, e-0, e-0, blue-2, e-0],
                       [white-4, e-0, e-0, e-0, blue-2]], blue, [blue-0, white-0], play),
    game_over(GameState, Winner), % Assert that the game is over
    Winner = blue, % Assert that the winner is blue
    format('Game over! Winner: ~w~n', [Winner]). % Debugging output

% Test: The player should be able to skip their turn
test(player_can_skip_turn) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, blue-2]], blue, [blue-0, white-0], play),
    move(GameState, skip, NewGameState),
    NewGameState = state([[blue-2, n-1, n-1, n-1, white-2],
                          [blue-2, n-1, n-1, n-1, n-1],
                          [n-1, n-1, blue-2, n-1, white-2],
                          [n-1, n-1, n-1, blue-2, n-1],
                          [white-2, white-2, n-1, n-1, blue-2]], white, [blue-0, white-0], play), !,
    format('Player can skip their turn.~n', []).

% Test: The player should be able to place a piece on the board
test(player_can_place_piece_on_board) :-
    GameState = state([[n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1]], blue, [blue-4, white-4], setup),
    move(GameState, place(1, 1), NewGameState),
    NewGameState = state([[blue-2, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1]], white, [blue-3, white-4], setup), !,
    format('Player can place a piece on the board.~n', []).

% Test: The player should be able to stack a piece on top of another
test(player_can_stack_a_stack_on_top_of_another_stack) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], blue, [blue-0, white-0], play),
    move(GameState, stack(1, 1, 2, 1), NewGameState),
    NewGameState = state([[e-0, n-1, n-1, n-1, white-2],
                          [blue-4, n-1, n-1, n-1, n-1],
                          [n-1, n-1, blue-2, n-1, white-2],
                          [n-1, n-1, n-1, blue-2, n-1],
                          [white-2, white-2, n-1, n-1, n-1]], white, [blue-0, white-0], play), !,
    format('Player can stack a stack on top of another.~n', []).

% Test: The player can stack a stack on top of a neutral cell
test(player_can_stack_a_stack_on_top_of_a_neutral_cell) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], blue, [blue-0, white-0], play),
    move(GameState, stack(1, 1, 1, 2), NewGameState),
    NewGameState = state([[e-0, blue-3, n-1, n-1, white-2],
                          [blue-2, n-1, n-1, n-1, n-1],
                          [n-1, n-1, blue-2, n-1, white-2],
                          [n-1, n-1, n-1, blue-2, n-1],
                          [white-2, white-2, n-1, n-1, n-1]], white, [blue-0, white-0], play), !,
    format('Player can stack a stack on top of a neutral cell.~n', []).

% Test: The player cannot stack a stack on top of an opponent's stack
test(player_cannot_stack_a_stack_on_top_of_an_opponents_stack) :-
    GameState = state([[blue-2, white-2, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, n-1, n-1, n-1, n-1]], blue, [blue-0, white-0], play),
    \+ move(GameState, stack(1, 1, 1, 2), _),% Assert that the move is invalid
    GameState = state([[blue-2, white-2, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, n-1, n-1, n-1, n-1]], blue, [blue-0, white-0], play), !,
    format('Player cannot stack a stack on top of an opponent''s stack.~n', []).

:- end_tests(game_tests).
