% ['/Users/tomassilva/pfl-prolog-project/game.pl'].  % Load the game file
% game.pl - Contains the main game loop and setup

:- [display, logic, ai, tests].  % Include other modules.

:- use_module(library(lists)).
:- use_module(library(between)).
:- use_module(library(plunit)).
:- use_module(library(random)).

% play
% Display the game menu and start the game
%
% The `play/0` predicate is the main entry point for starting the game. It follows a structured sequence of steps to 
% initialize and run the game:
%
% 1. Seed the Random Number Generator:
%    The `seed_random/0` predicate is called to seed the random number generator. This ensures that any random choices
%    made during the game (e.g., by the AI) are reproducible and not purely deterministic. The seed is based on the current 
%    runtime in milliseconds, providing a unique seed for each game session.
%
% 2. Display the Game Menu:
%    The `display_menu/0` predicate is called to present the game menu to the player. This menu allows the player to select 
%    the game type (e.g., Human vs Human, Human vs Computer, etc.). The player's choice is read and stored in the `GameType` 
%    variable.
%
% 3. Configure the Game:
%    The `configure_game/4` predicate is called with the selected `GameType`. This predicate sets up the game configuration
%    (`GameConfig`), including the board size, player types, and difficulty levels for AI players. The configuration is tailored 
%    based on the selected game type, ensuring that the game is set up correctly for the chosen mode.
%
% 4. Initialize the Game State:
%    The `initial_state/2` predicate is called with the `GameConfig` to set up the initial game state (`GameState`). This 
%    includes initializing the board, setting the initial player, and placing the initial pieces on the board. The game state 
%    is represented by a `state/5` structure, which includes the board, current player, remaining pieces, game phase, and board size.
%
% 5. Enter the Game Loop:
%    The `game_loop/3` predicate is called with the initial `GameState` and the difficulty levels for the AI players 
%    (`Difficulty1` and `Difficulty2`). The game loop handles the main gameplay, including player moves, game state updates, 
%    and checking for game-over conditions. The loop continues until the game ends, either by a player winning or by a tie.
%
% The `play/0` predicate encapsulates the entire game setup and execution process, providing a seamless experience for the 
% player from the initial menu to the end of the game.
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
configure_game(1, [board_size(BoardSize), player1(blue), player2(white), player1_name('Player 1'), player2_name('Player 2')], _, _) :-
    ask_board_size(BoardSize),
    format('Starting Human vs Human game with board size ~w...~n', [BoardSize]).
configure_game(2, [board_size(BoardSize), player1(blueH), player2(whitePC), difficulty(Difficulty), player1_name('Player 1'), player2_name('Computer')], Difficulty, _) :-
    ask_board_size(BoardSize),
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    prompt(_, 'Enter your choice (1-3): '),
    read(Difficulty),
    prompt(_, '|: '),  % Reset the prompt to the default
    format('Starting Human vs Computer game with board size ~w and difficulty level ~w...~n', [BoardSize, Difficulty]).
configure_game(3, [board_size(BoardSize), player1(bluePC), player2(whiteH), difficulty(Difficulty), player1_name('Computer'), player2_name('Player 2')], Difficulty, _) :-
    ask_board_size(BoardSize),
    format('Select difficulty level for Computer:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    prompt(_, 'Enter your choice (1-3): '),
    read(Difficulty),
    prompt(_, '|: '),  % Reset the prompt to the default
    format('Starting Computer vs Human game with board size ~w and difficulty level ~w...~n', [BoardSize, Difficulty]).
configure_game(4, [board_size(BoardSize), player1(computer1), player2(computer2), player1_name('Computer 1'), player2_name('Computer 2')], Difficulty1, Difficulty2) :-
    ask_board_size(BoardSize),
    format('Select difficulty level for Computer 1:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    prompt(_, 'Enter your choice (1-3): '),
    read(Difficulty1),
    prompt(_, '|: '),  % Reset the prompt to the default
    format('Select difficulty level for Computer 2:~n', []),
    format('1. Random~n', []),
    format('2. Greedy~n', []),
    format('3. Minimax~n', []),
    prompt(_, 'Enter your choice (1-3): '),
    read(Difficulty2),
    prompt(_, '|: '),  % Reset the prompt to the default
    format('Starting Computer vs Computer game with board size ~w and difficulty levels ~w and ~w...~n', [BoardSize, Difficulty1, Difficulty2]).

% Ask the user for the board size
ask_board_size(BoardSize) :-
    prompt(_, 'Enter the board size from 4 to 10 (e.g., 5 for a 5x5 board): '),
    read(BoardSize),
    integer(BoardSize),
    BoardSize >= 4,
    BoardSize =< 10,
    prompt(_, '|: ').  % Reset the prompt to the default

% initial_state(+GameConfig, -GameState)
% Sets up the initial game state based on the provided configuration.
%
% The `initial_state/2` predicate initializes the game state by configuring the board, players, pieces, and game phase. 
% It follows these steps:
%
% 1. Extract Configuration Parameters:
%    The predicate extracts various configuration parameters from the `GameConfig` list, including the board size, player types, 
%    player names, and difficulty level. Default values are used if any parameters are missing.
%
% 2. Initialize the Board:
%    The `initialize_board/2` predicate is called to create the initial board based on the specified board size. Each cell on 
%    the board is initialized with a neutral piece (`n-1`).
%
% 3. Set the Initial Player:
%    The initial player is set to `Player1`, as specified in the configuration.
%
% 4. Set the Initial Pieces:
%    The number of initial pieces for each player is determined based on the board size. Larger boards receive more pieces 
%    to maintain balanced gameplay. The pieces are represented as a list of player-piece count pairs.
%
% 5. Set the Initial Phase:
%    The game phase is initially set to `setup`, indicating that players will place their pieces on the board.
%
% 6. Print the Game Configuration:
%    For information purposes, the game configuration is printed to the console, including the board size, player types, and 
%    player names.
%
% The `initial_state/2` predicate ensures that the game is correctly initialized with all necessary parameters, providing a 
% consistent starting point for the game loop.
initial_state(GameConfig, GameState) :-
    GameState = state(Board, CurrentPlayer, Pieces, Phase, BoardSize),
    % Extract configuration parameters
    ( member(board_size(BoardSize), GameConfig) -> true ; BoardSize = 5 ),
    ( member(player1(Player1), GameConfig) -> true ; Player1 = blue ),
    ( member(player2(Player2), GameConfig) -> true ; Player2 = white ),
    ( member(player1_name(Player1Name), GameConfig) -> true ; Player1Name = 'Player 1' ),
    ( member(player2_name(Player2Name), GameConfig) -> true ; Player2Name = 'Player 2' ),
    ( member(difficulty(Level), GameConfig) -> true ; Level = 1 ),
    
    % Initialize the board based on the board size
    initialize_board(BoardSize, Board),
    
    % Set the initial player
    CurrentPlayer = Player1,
    
    % Set the initial pieces for each player based on the board size
    TotalCells is BoardSize * BoardSize,
    InitialPieces is round(TotalCells * 0.32 / 2),  % 32% of the total cells, divided by 2 for each player
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
