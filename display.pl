% display.pl - Contains the game display logic

% display.pl - Contains the game display logic

% Initialize the board based on the board size
initialize_board(BoardSize, Board) :-
    length(Board, BoardSize),
    maplist(initialize_row(BoardSize), Board).

% Initialize a row with neutral pieces
initialize_row(BoardSize, Row) :-
    length(Row, BoardSize),
    maplist(=(n-1), Row).

% display_game(+GameState)
% Display the game state
display_game(GameState) :-
    GameState = state(Board, Player, Pieces, Phase, BoardSize),
    length(Board, BoardSize),  % Determine the board size
    print_board(Board, BoardSize),
    format('Current player: ~w~n', [Player]),
    format_pieces(Pieces),
    format('Current phase: ~w~n', [Phase]).

% Print the entire board with borders
print_board(Board, BoardSize) :-
    write('  |'),
    print_column_headers(1, BoardSize), nl,  % Column headers
    write('--+'),
    print_row_borders(1, BoardSize), nl,
    print_board_rows(Board, 1, BoardSize).  % Start printing rows with indices

% Print column headers
print_column_headers(Col, BoardSize) :-
    Col =< BoardSize,
    format('       ~d       |', [Col]),
    NextCol is Col + 1,
    print_column_headers(NextCol, BoardSize).
print_column_headers(Col, BoardSize) :-
    Col > BoardSize.

% Print row borders
print_row_borders(Col, BoardSize) :-
    Col =< BoardSize,
    write('---------------+'),
    NextCol is Col + 1,
    print_row_borders(NextCol, BoardSize).
print_row_borders(Col, BoardSize) :-
    Col > BoardSize.

% Print each row with borders and row indices
print_board_rows([], _, _).
print_board_rows([Row|Rest], RowIndex, BoardSize) :-
    format('~d |', [RowIndex]),  % Row index
    print_row(Row, BoardSize), nl,
    write('--+'),
    print_row_borders(1, BoardSize), nl,  % Row border
    NextRowIndex is RowIndex + 1,
    print_board_rows(Rest, NextRowIndex, BoardSize).

% Print a single row with vertical dividers
print_row([], _).
print_row([Cell|Rest], BoardSize) :-
    write_piece(Cell),
    write('|'),
    print_row(Rest, BoardSize).

% Write a piece or stack with fixed width for all cells
write_piece(n-1) :- format('~|~` t~w~15+', ['neutral-1']).
write_piece(e-0) :- format('~|~` t~w~15+', ['empty-0']).
write_piece(Player1-Count) :- format('~|~` t~w-~d~15+', [Player1, Count]).
write_piece(Player2-Count) :- format('~|~` t~w-~d~15+', [Player2, Count]).

% Display Pieces in proper format
format_pieces([blue-N, white-M]) :-
    format('blue: ~d pieces, white: ~d pieces~n', [N, M]).
format_pieces([blueH-N, whitePC-M]) :-
    format('blue: ~d pieces, computer: ~d pieces~n', [N, M]).
format_pieces([bluePC-N, whiteH-M]) :-
    format('computer: ~d pieces, white: ~d pieces~n', [N, M]).
format_pieces([computer1-N, computer2-M]) :-
    format('computer1: ~d pieces, computer2: ~d pieces~n', [N, M]).
format_pieces([computer2-N, computer1-M]) :-
    format('computer2: ~d pieces, computer1: ~d pieces~n', [N, M]).
format_pieces(Pieces) :-
    format('Error: Invalid Pieces list: ~w~n', [Pieces]),
    fail.