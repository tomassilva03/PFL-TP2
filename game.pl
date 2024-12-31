% ['/Users/tomassilva/pfl-prolog-project/game.pl'].  % Load the game file
% game.pl - Contains the main game loop and setup

:- [display, logic, ai, tests].  % Include other modules.

:- use_module(library(lists)).
:- use_module(library(between)).
:- use_module(library(plunit)).
:- use_module(library(random)).

% play
% Display the game menu and start the game
play :-
    seed_random,
    display_menu,
    read(GameType),
    configure_game(GameType, GameConfig, Difficulty1, Difficulty2),
    initial_state(GameConfig, GameState),
    game_loop(GameState, Difficulty1, Difficulty2).

% seed_random
% Seed the random number generator
seed_random :-
    statistics(runtime, [Milliseconds|_]),
    Seed is Milliseconds mod 10000,
    setrand(Seed).

% display_menu
% Display the game menu
display_menu :-
    format('Welcome to the Game of STAQS!~n', []),
    format('Select game type:~n', []),
    format('1. Human vs Human (H/H)~n', []),
    format('2. Human vs Computer (H/PC)~n', []),
    format('3. Computer vs Human (PC/H)~n', []),
    format('4. Computer vs Computer (PC/PC)~n', []),
    format('Enter your choice (1-4): ', []).

% configure_game(+GameType, -GameConfig, -Difficulty1, -Difficulty2)
% Configure the game based on the selected game type
configure_game(1, [board_size(BoardSize), player1(blue), player2(white), optional_rules([]), player1_name('Player 1'), player2_name('Player 2')], _, _) :-
    ask_board_size(BoardSize),
    format('Starting Human vs Human game with board size ~w...~n', [BoardSize]).
configure_game(2, [board_size(BoardSize), player1(blueH), player2(whitePC), difficulty(Difficulty), optional_rules([]), player1_name('Player 1'), player2_name('Computer')], Difficulty, _) :-
    ask_board_size(BoardSize),
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Difficulty),
    format('Starting Human vs Computer game with board size ~w and difficulty level ~w...~n', [BoardSize, Difficulty]).
configure_game(3, [board_size(BoardSize), player1(bluePC), player2(whiteH), difficulty(Difficulty), optional_rules([]), player1_name('Computer'), player2_name('Player 2')], Difficulty, _) :-
    ask_board_size(BoardSize),
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Difficulty),
    format('Starting Computer vs Human game with board size ~w and difficulty level ~w...~n', [BoardSize, Difficulty]).
configure_game(4, [board_size(BoardSize), player1(computer1), player2(computer2), optional_rules([]), player1_name('Computer 1'), player2_name('Computer 2')], Difficulty1, Difficulty2) :-
    ask_board_size(BoardSize),
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
    format('Starting Computer vs Computer game with board size ~w and difficulty levels ~w and ~w...~n', [BoardSize, Difficulty1, Difficulty2]).

% Ask the user for the board size
ask_board_size(BoardSize) :-
    format('Enter the board size from 4 to 10 (e.g., 5 for a 5x5 board): ', []),
    read(BoardSize),
    integer(BoardSize),
    BoardSize >= 4,
    BoardSize =< 10.

% initial_state(+GameConfig, -GameState)
% Sets up the initial game state based on the provided configuration.
initial_state(GameConfig, GameState) :-
    GameState = state(Board, CurrentPlayer, Pieces, Phase, BoardSize),
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
    
    % Set the initial pieces for each player based on the board size
    ( BoardSize >= 7 ->
        InitialPieces = 6  % More pieces for larger boards
    ; 
        InitialPieces = 4  % Default number of pieces
    ),
    Pieces = [Player1-InitialPieces, Player2-InitialPieces],
    
    % Set the initial phase
    Phase = setup,
    
    % Print the game configuration for debugging
    format('Game configuration:~n', []),
    format('Board size: ~w~n', [BoardSize]),
    format('Player 1: ~w (~w)~n', [Player1, Player1Name]),
    format('Player 2: ~w (~w)~n', [Player2, Player2Name]).

% game_loop(+GameState, +Difficulty1, +Difficulty2)
% Main game loop
game_loop(GameState, Difficulty1, Difficulty2) :-
    display_game(GameState),
    ( game_over(GameState, Winner) ->
        ( Winner = e ->
            format('No more valid moves. The game is a tie!~n', [])
        ;
            % Determine the tallest stack for the winner
            GameState = state(Board, _, _, _, _),
            tallest_stack(Board, Winner, TallestStack),
            format('No more valid moves. Game over! Winner: ~w with the tallest stack of ~d pieces!~n', [Winner, TallestStack])
        )
    ; get_player_move(GameState, Difficulty1, Difficulty2, Move),
      move(GameState, Move, NewGameState),
      game_loop(NewGameState, Difficulty1, Difficulty2)
    ).
