defmodule PhoenixRoyale.Game do
  alias PhoenixRoyale.GameServer

  def jump(player_number, state) do
    player = Map.get(state.players, player_number)

    updated_player =
      if player.started do
        Map.update!(player, :started, fn _x -> true end)
      else
        Map.update!(player, :y_acc, fn y_acc -> modify_acceleration(y_acc) end)
      end

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def modify_acceleration(y_acc) do
    y_acc * 0.7 + 60
  end

  def slow(player_number, 1, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :x_speed, fn x -> x - 1 end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def kill(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :alive, fn _x -> false end)
    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players, alive_count: state.alive_count - 1}}
  end

  def tick(state) do
    players_list = Map.to_list(state.players)

    updated_players = Map.new(Enum.map(players_list, &tick_player(&1, state)))

    %{
      state
      | players: updated_players,
        storm: state.storm + state.storm_speed,
        storm_speed: state.storm_speed + 0.001
    }
  end

  def tick_player({player_number, %{alive: false} = player_state} = _player, _state),
    do: {player_number, player_state}

  def tick_player(
        {player_number, %{y: y, y_acc: y_acc, x: x, x_speed: x_speed} = player_state},
        state
      ) do
    if state.storm > x do
      GameServer.kill(player_number, state.uuid)
    end

    Task.start(fn -> check_collisions(player_number, {x, y}, state) end)

    updated_state = update_coords(player_state, x, y, x_speed, y_acc)

    {player_number, updated_state}
  end

  def update_coords(player_state, x, y, x_speed, y_acc) when y > 0 do
    %{
      player_state
      | y: y + y_acc * 0.08,
        y_acc: y_acc - 4,
        x: x + 1 * x_speed,
        x_speed: x_speed + 0.006
    }
  end

  def update_coords(player_state, x, y, x_speed, y_acc) do
    %{
      player_state
      | y: y + y_acc * 0.03,
        y_acc: y_acc + 4,
        x: x + 0.2 * x_speed,
        x_speed: x_speed + 0.003
    }
  end

  def check_collisions(player_number, {x, y}, %{game_map: map, uuid: uuid} = state) do
    {x, y}
    |> check_trees(map.trees)
    |> case do
      true ->
        GameServer.slow(player_number, 1, uuid)

      # GameServer.kill(player_number, uuid)

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
    trees = generate_trees([{500, 25}], 500)
    %{trees: trees}
  end

  def generate_trees(trees_so_far, total_x) do
    if total_x >= 200_000 do
      Enum.reverse(trees_so_far)
    else
      new_tree_x = total_x + Enum.random(400..800)
      new_tree_y = Enum.random(0..70)
      new_tree = {new_tree_x, new_tree_y}
      generate_trees([new_tree | trees_so_far], new_tree_x)
    end
  end
end
