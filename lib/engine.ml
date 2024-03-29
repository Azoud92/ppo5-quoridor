open Types
open Board

let create_player pos walls_left color strat =
  {
    start_position = pos;
    current_position = pos;
    walls_left;
    color;
    strategy = strat;
  }

let add_players player_lst =
  let num_players = List.length player_lst in
  if num_players <> 2 && num_players <> 4 then
    raise
      (InvalidNumberPlayer
         (num_players, "Number of players must be 2 or 4 to start the game"))
  else if
    not (List.for_all (fun p -> p.walls_left = 20 / num_players) player_lst)
  then
    raise
      (InvalidPlayerWallsLeft
         "The number of walls for each player is not allowed")
  else add_all_players_to_board player_lst

let run_game players =
  let nb_players = List.length players in
  (* Creates and returns the list of players with their position, color and our strategy
      @param nb_players The number of players to add to the game
      @raise InvalidNumberPlayer if the number of players is not 2 or 4.
      @return the list of players to add to the game
  *)
  let create_lst_of_player players walls_left =
    let colors = [ Red; Blue; Green; Yellow ] in
    let positions =
      [
        (board_size / 2, 0);
        (board_size / 2, board_size - 1);
        (0, board_size / 2);
        (board_size - 1, board_size / 2);
      ]
    in
    if nb_players <> 2 && nb_players <> 4 then
      raise
        (InvalidNumberPlayer
           (nb_players, "Number of players must be 2 or 4 to start the game"))
    else
      players
      |> List.mapi (fun i player ->
             create_player (List.nth positions i) walls_left (List.nth colors i)
               player)
  in
  let rec aux n =
    if n > 5000 then failwith "Diverging";
    (* Board.print_board (); *)
    try Board.winning_player ()
    with NoWinningPlayer _ ->
      Board.play ();
      aux (n + 1)
  in
  let player_lst = create_lst_of_player players (20 / nb_players) in
  add_players player_lst;
  Board.start_game ();
  aux 0

(**This function returns a movement with a position where the player moves based on their current position
    @param pos the player's initial position
    @raise NoMovePossible when the player has no possible movement
    @return the position where the player must move  *)
let random_move pos =
  let lstMv = list_of_moves pos in
  match lstMv with
  | [] -> raise (NoMovePossible "There is no movement possible for this player")
  | _ ->
      let r = Random.int (List.length lstMv) in
      let newPos = List.nth lstMv r in
      Moving newPos

(**This function returns 2 random positions where we will and we can place a wall*)
let pos_wall_random () =
  let rec generate_random_wall_pos () =
    let x1 = Random.int board_size in
    let y1 = Random.int board_size in
    let r = Random.int 4 in
    let xv, yv = List.nth move_vectors r in
    try
      validate_wall_placement (current_player ()).walls_left (x1, y1)
        (x1 + xv, y1 + yv);
      ((x1, y1), (x1 + xv, y1 + yv))
    with
    | InvalidWallPosition _ -> generate_random_wall_pos ()
    | InvalidPosition _ -> generate_random_wall_pos ()
    | InvalidWallPlacement _ -> generate_random_wall_pos ()
  in
  let wall_pos1, wall_pos2 = generate_random_wall_pos () in
  Placing_wall (wall_pos1, wall_pos2)

(** This function defines our strategy for our players which is to play randomly*)
let random_player pos =
  let r = Random.int 3 in
  if r == 0 && (current_player ()).walls_left > 0 then pos_wall_random ()
  else random_move pos
