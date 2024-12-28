% tests.pl - Contains the game tests

:- use_module(library(plunit)). % Load the test framework

% Tests
:- begin_tests(game_tests).

% Test: The game should not end if valid moves exist
test(game_not_ended_with_valid_moves) :-
    GameState = state([[blue-7, n-1, e-0, e-0, white-5],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, blue-2, e-0, white-3],
                       [e-0, e-0, e-0, blue-2, e-0],
                       [white-4, e-0, e-0, e-0, blue-2]], blue, [blue-0, white-0], play),
    \+ game_over(GameState, _). % Assert that the game is not over

% Test: The game should end if no more valid moves exist and a winner is determined
test(game_ended_with_no_valid_moves_and_winner_blue) :-
    GameState = state([[blue-7, e-0, e-0, e-0, white-5],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, blue-2, e-0, white-3],
                       [e-0, e-0, e-0, blue-2, e-0],
                       [white-4, e-0, e-0, e-0, blue-2]], blue, [blue-0, white-0], play),
    game_over(GameState, Winner), % Assert that the game is over
    Winner = blue, !. % Assert that the winner is blue

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
                          [white-2, white-2, n-1, n-1, blue-2]], white, [blue-0, white-0], play), !.

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
                          [n-1, n-1, n-1, n-1, n-1]], white, [blue-3, white-4], setup), !.

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
                          [white-2, white-2, n-1, n-1, n-1]], white, [blue-0, white-0], play), !.

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
                          [white-2, white-2, n-1, n-1, n-1]], white, [blue-0, white-0], play), !.

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
                       [white-2, n-1, n-1, n-1, n-1]], blue, [blue-0, white-0], play), !.

% Test: When game ends with draw in the tallest stack the winner should be the player with the second tallest stack
test(game_ended_with_winner_white_after_draw) :-
    GameState = state([[blue-9, e-0, e-0, e-0, white-9],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, blue-7, e-0, white-7],
                       [e-0, e-0, e-0, blue-2, e-0],
                       [white-4,e-0, e-0, e-0, e-0]], blue, [blue-0, white-0], play),
    game_over(GameState, Winner), % Assert that the game is over
    Winner = white, !. % Assert that the winner is blue

% Test: Game ends in a draw
test(game_ended_with_draw) :-
    GameState = state([[blue-9, e-0, e-0, e-0, white-9],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0,e-0, e-0, e-0, e-0]], blue, [blue-0, white-0], play),
    game_over(GameState, Winner), % Assert that the game is over
    Winner = e, !. % Assert that the game is a draw
:- end_tests(game_tests).
