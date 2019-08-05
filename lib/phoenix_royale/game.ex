defmodule PhoenixRoyale.Game do
  alias PhoenixRoyale.GameServer

  def jump(player_number, state) do
    player = Map.get(state.players, player_number)

    updated_player =
      if player.started do
        Map.update!(player, :started, fn _x -> true end)
      else
        Map.update!(player, :y_acc, fn y_acc -> y_acc + 100 end)
      end

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def kill(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :alive, fn _x -> false end)
    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def tick(state) do
    players_list = Map.to_list(state.players)

    updated_players = Map.new(Enum.map(players_list, &tick_player(&1, state)))

    %{state | players: updated_players}
  end

  def tick_player({player_number, %{alive: false} = player_state} = _player, _state),
    do: {player_number, player_state}

  def tick_player(
        {player_number, %{y: y, y_acc: y_acc, x: x, x_acc: x_acc} = player_state},
        state
      ) do
    Task.start(fn -> check_collisions(player_number, {x, y}, state.game_map) end)

    updated_state = %{
      player_state
      | y: y + y_acc * 0.02,
        y_acc: y_acc - 4,
        x: x + 1 * x_acc,
        x_acc: x_acc + 0.02
    }

    {player_number, updated_state}
  end

  def check_collisions(player_number, {x, y}, map) do
    {x, y}
    |> check_trees(map.trees)
    |> case do
      true ->
        nil

      # GameServer.kill(player_number)

      false ->
        nil
    end
  end

  def check_trees({x, y}, trees) do
    Enum.any?(trees, fn {tree_x, tree_y} ->
      tree_x - round(x) <= 5 && tree_x - x >= -5 && (y - tree_y < 0 || y - tree_y > 40)
    end)
  end

  def generate_map() do
    trees = generate_trees([], 0)
    %{trees: trees}
  end

  def generate_trees(trees_so_far, total_x) do
    if total_x >= 10000 do
      Enum.reverse(trees_so_far)
    else
      new_tree_x = total_x + Enum.random(250..400)
      new_tree_y = Enum.random(0..70)
      new_tree = {new_tree_x, new_tree_y}
      generate_trees([new_tree | trees_so_far], new_tree_x)
    end
  end
end
