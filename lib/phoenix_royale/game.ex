defmodule PhoenixRoyale.Game do
  def tick(state) do
    players_list = Map.to_list(state.players)

    updated_players =
      Map.new(
        Enum.map(players_list, fn player ->
          {player_number, player_state} = player

          new_player_state =
            if player_state.alive do
              if alive?(player_state, state) do
                %{
                  player_state
                  | y: player_state.y + player_state.y_acc * 0.03,
                    y_acc: player_state.y_acc - 4,
                    x: player_state.x + 1 * player_state.x_acc,
                    x_acc: player_state.x_acc + 0.01
                }
              else
                %{
                  player_state
                  | alive: false
                }
              end
            else
              player_state
            end

          {player_number, new_player_state}
        end)
      )

    %{state | players: updated_players}
  end

  def alive?(%{x: x, y: y} = _player_state, %{game_map: %{trees: trees}} = _game_state) do
    if y < 0 || y > 100 do
      false
    else
      if Enum.any?(trees, fn {tree_x, tree_y} ->
           tree_x - round(x) <= 5 && tree_x - x >= -5 && (y - tree_y < 0 || y - tree_y > 40)
         end) do
        false
      else
        true
      end
    end
  end

  def generate_map() do
    trees = generate_trees([], 0)
    %{trees: trees}
  end

  def generate_trees(trees_so_far, total_x) do
    if total_x >= 1000 do
      Enum.reverse(trees_so_far)
    else
      new_tree_x = total_x + Enum.random(30..70)
      new_tree_y = Enum.random(25..50)
      new_tree = {new_tree_x, new_tree_y}
      generate_trees([new_tree | trees_so_far], new_tree_x)
    end
  end
end
