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
                       [white-4, e-0, e-0, e-0, blue-2]], blue, [blue-0, white-0], play, 5),
    \+ game_over(GameState, _). % Assert that the game is not over

% Test: The game should end if no more valid moves exist and a winner is determined
test(game_ended_with_no_valid_moves_and_winner_blue) :-
    GameState = state([[blue-7, e-0, e-0, e-0, white-5],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, blue-2, e-0, white-3],
                       [e-0, e-0, e-0, blue-2, e-0],
                       [white-4, e-0, e-0, e-0, blue-2]], blue, [blue-0, white-0], play, 5),
    game_over(GameState, Winner), % Assert that the game is over
    Winner = blue, !. % Assert that the winner is blue

% Test: The player should be able to skip their turn
test(player_can_skip_turn) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, blue-2]], blue, [blue-0, white-0], play, 5),
    move(GameState, skip, NewGameState),
    NewGameState = state([[blue-2, n-1, n-1, n-1, white-2],
                          [blue-2, n-1, n-1, n-1, n-1],
                          [n-1, n-1, blue-2, n-1, white-2],
                          [n-1, n-1, n-1, blue-2, n-1],
                          [white-2, white-2, n-1, n-1, blue-2]], white, [blue-0, white-0], play, 5), !.

% Test: The player should be able to place a piece on the board
test(player_can_place_piece_on_board) :-
    GameState = state([[n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1]], blue, [blue-4, white-4], setup, 5),
    move(GameState, place(1, 1), NewGameState),
    NewGameState = state([[blue-2, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1],
                          [n-1, n-1, n-1, n-1, n-1]], white, [blue-3, white-4], setup, 5), !.

% Test: The player should be able to stack a piece on top of another
test(player_can_stack_a_stack_on_top_of_another_stack) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], blue, [blue-0, white-0], play, 5),
    move(GameState, stack(1, 1, 2, 1), NewGameState),
    NewGameState = state([[e-0, n-1, n-1, n-1, white-2],
                          [blue-4, n-1, n-1, n-1, n-1],
                          [n-1, n-1, blue-2, n-1, white-2],
                          [n-1, n-1, n-1, blue-2, n-1],
                          [white-2, white-2, n-1, n-1, n-1]], white, [blue-0, white-0], play, 5), !.

% Test: The player can stack a stack on top of a neutral cell
test(player_can_stack_a_stack_on_top_of_a_neutral_cell) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], blue, [blue-0, white-0], play, 5),
    move(GameState, stack(1, 1, 1, 2), NewGameState),
    NewGameState = state([[e-0, blue-3, n-1, n-1, white-2],
                          [blue-2, n-1, n-1, n-1, n-1],
                          [n-1, n-1, blue-2, n-1, white-2],
                          [n-1, n-1, n-1, blue-2, n-1],
                          [white-2, white-2, n-1, n-1, n-1]], white, [blue-0, white-0], play, 5), !.

% Test: When game ends with draw in the tallest stack the winner should be the player with the second tallest stack
test(game_ended_with_winner_white_after_draw) :-
    GameState = state([[blue-9, e-0, e-0, e-0, white-9],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, blue-7, e-0, white-7],
                       [e-0, e-0, e-0, blue-2, e-0],
                       [white-4,e-0, e-0, e-0, e-0]], blue, [blue-0, white-0], play, 5),
    game_over(GameState, Winner), % Assert that the game is over
    Winner = white, !. % Assert that the winner is blue

% Test: Game ends in a draw
test(game_ended_with_draw) :-
    GameState = state([[blue-9, e-0, e-0, e-0, white-9],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0, e-0, e-0, e-0, e-0],
                       [e-0,e-0, e-0, e-0, e-0]], blue, [blue-0, white-0], play, 5),
    game_over(GameState, Winner), % Assert that the game is over
    Winner = e, !. % Assert that the game is a draw

% Test: Invalid move during setup phase (placing outside the board boundaries)
test(invalid_move_setup_outside_boundaries) :-
    GameState = state([[n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1]], blue, [blue-4, white-4], setup, 5),
    \+ valid_move(GameState, place(6, 1)). % Assert that the move is invalid

% Test: Invalid move during setup phase (placing on an occupied cell)
test(invalid_move_setup_occupied_cell) :-
    GameState = state([[blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1]], white, [blue-3, white-4], setup, 5),
    \+ valid_move(GameState, place(1, 1)). % Assert that the move is invalid

% Test: Invalid move during play phase (stacking on a non-adjacent cell)
test(invalid_move_play_non_adjacent_cell) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], blue, [blue-0, white-0], play, 5),
    \+ valid_move(GameState, stack(1, 1, 3, 3)). % Assert that the move is invalid

% Test: Invalid move during play phase (stacking on a non-orthogonal cell)
test(invalid_move_play_non_orthogonal_cell) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], blue, [blue-0, white-0], play, 5),
    \+ valid_move(GameState, stack(1, 1, 2, 2)). % Assert that the move is invalid

% Test: Invalid move during play phase (stacking from an opponent's cell)
test(invalid_move_play_opponents_cell) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], blue, [blue-0, white-0], play, 5),
    \+ valid_move(GameState, stack(1, 5, 1, 4)). % Assert that the move is invalid

% Test: Game transitions from setup to play phase
test(game_transition_setup_to_play) :-
    GameState = state([[n-1, n-1, blue-2, n-1, blue-2],
                        [n-1, n-1, n-1, n-1, n-1],
                        [n-1, n-1, white-2, blue-2, white-2],
                        [n-1, blue-2, n-1, n-1, n-1],
                        [blue-2, n-1, white-2, n-1, n-1]], white, [blue-0, white-1], setup, 5),
    move(GameState, place(1, 1), NewGameState),
    NewGameState = state([[white-2, n-1, blue-2, n-1, blue-2],
                          [n-1, n-1, n-1, n-1, n-1],
                          [n-1, n-1, white-2, blue-2, white-2],
                          [n-1, blue-2, n-1, n-1, n-1],
                          [blue-2, n-1, white-2, n-1, n-1]], blue, [blue-0, white-0], play, 5), !.

% Test: Random AI makes a valid move in setup
test(random_ai_makes_valid_move_setup) :-
    GameState = state([[n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1],
                       [n-1, n-1, n-1, n-1, n-1]], bluePC, [blue-4, white-4], setup, 5),
    get_player_move(GameState, 1, _, Move),
    valid_move(GameState, Move), !.

% Test: Random AI makes a valid move in play
test(random_ai_makes_valid_move_play) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], bluePC, [blue-0, white-0], play, 5),
    get_player_move(GameState, 1, _, Move),
    valid_move(GameState, Move), !.

% Test: Greedy AI makes a valid move in play
test(greedy_ai_makes_valid_move_play) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], bluePC, [blue-0, white-0], play, 5),
    get_player_move(GameState, 2, _, Move),
    valid_move(GameState, Move), !.

% Test: Minimax AI makes a valid move in play
test(minimax_ai_makes_valid_move_play) :-
    GameState = state([[blue-2, n-1, n-1, n-1, white-2],
                       [blue-2, n-1, n-1, n-1, n-1],
                       [n-1, n-1, blue-2, n-1, white-2],
                       [n-1, n-1, n-1, blue-2, n-1],
                       [white-2, white-2, n-1, n-1, n-1]], bluePC, [blue-0, white-0], play, 5),
    get_player_move(GameState, 3, _, Move),
    valid_move(GameState, Move), !.

% Test: Game initializes correctly with different board sizes
test(game_initializes_with_different_board_sizes) :-
    initial_state([board_size(4), player1(blue), player2(white)], GameState4),
    GameState4 = state(Board4, blue, [blue-4, white-4], setup, 4),
    length(Board4, 4),
    maplist(length_(4), Board4),
    initial_state([board_size(6), player1(blue), player2(white)], GameState6),
    GameState6 = state(Board6, blue, [blue-4, white-4], setup, 6),
    length(Board6, 6),
    maplist(length_(6), Board6).

length_(Length, List) :- length(List, Length).

:- end_tests(game_tests).
