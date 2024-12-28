% ['/Users/tomassilva/pfl-prolog-project/game.pl'].  % Load the game file
% game.pl - Contains the main game loop and setup

:- [display, logic, ai, tests].  % Include other modules.

:- use_module(library(lists)).
:- use_module(library(between)).
:- use_module(library(plunit)).
:- use_module(library(random)).

% Display the game menu and start the game
% game.pl
play :-
    seed_random,
    display_menu,
    read(GameType),
    configure_game(GameType, GameConfig, Difficulty1, Difficulty2),
    initial_state(GameConfig, GameState),
    game_loop(GameState, Difficulty1, Difficulty2).

% Seed the random number generator
% game.pl
seed_random :-
    statistics(runtime, [Milliseconds|_]),
    Seed is Milliseconds mod 10000,
    setrand(Seed).

% Display the game menu
% game.pl
display_menu :-
    format('Welcome to the Game of STAQS!~n', []),
    format('Select game type:~n', []),
    format('1. Human vs Human (H/H)~n', []),
    format('2. Human vs Computer (H/PC)~n', []),
    format('3. Computer vs Human (PC/H)~n', []),
    format('4. Computer vs Computer (PC/PC)~n', []),
    format('Enter your choice (1-4): ', []).

% Configure the game based on the selected game type
% game.pl
configure_game(1, [board_size(5), player1(blue), player2(white), optional_rules([]), player1_name('Player 1'), player2_name('Player 2')], _, _) :-
    format('Starting Human vs Human game...~n', []).
configure_game(2, [board_size(5), player1(blueH), player2(whitePC), difficulty(Difficulty), optional_rules([]), player1_name('Player 1'), player2_name('Computer')], Difficulty, _) :-
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Difficulty),
    format('Starting Human vs Computer game with difficulty level ~w...~n', [Difficulty]).
configure_game(3, [board_size(5), player1(bluePC), player2(whiteH), difficulty(Difficulty), optional_rules([]), player1_name('Computer'), player2_name('Player 2')], Difficulty, _) :-
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    format('Enter your choice (1-3): ', []),
    read(Difficulty),
    format('Starting Computer vs Human game with difficulty level ~w...~n', [Difficulty]).
configure_game(4, [board_size(5), player1(computer1), player2(computer2), optional_rules([]), player1_name('Computer 1'), player2_name('Computer 2')], Difficulty1, Difficulty2) :-
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
% game.pl
game_loop(GameState, Difficulty1, Difficulty2) :-
    display_game(GameState),
    ( game_over(GameState, Winner) ->
        format('No more valid moves. Game over! Winner: ~w~n', [Winner])
    ; get_player_move(GameState, Difficulty1, Difficulty2, Move),
    move(GameState, Move, NewGameState),
    game_loop(NewGameState, Difficulty1, Difficulty2)).

% initial_state(+GameConfig, -GameState)
% Sets up the initial game state based on the provided configuration.
% game.pl
initial_state(GameConfig, GameState) :-
    GameState = state(Board, CurrentPlayer, Pieces, Phase),
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
    Pieces = [Player1-4, Player2-4], % Ensure this format is used regardless of Player2 being a computer or human
    
    % Set the initial phase
    Phase = setup,
    
    % Print the game configuration for debugging
    format('Game configuration:~n', []),
    format('Board size: ~w~n', [BoardSize]),
    format('Player 1: ~w (~w)~n', [Player1, Player1Name]),
    format('Player 2: ~w (~w)~n', [Player2, Player2Name]).