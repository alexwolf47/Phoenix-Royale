defmodule PhoenixRoyale.Game do
  alias PhoenixRoyale.{GameServer, GameInstance, GameSettings}

  @tick GameSettings.tick_rate()

  def jump(player_number, state) do
    player = Map.get(state.players, player_number)

    updated_player =
      if player.x > 30 do
        Map.update!(player, :y_speed, fn y_speed -> modify_speedeleration(y_speed) end)
      else
        player
      end

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def modify_speedeleration(y_speed) do
    y_speed * 0.6 + 50
  end

  def slow(player_number, value, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :x_speed, fn x -> x - value end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def pipe(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :pipe, fn _x -> player.x + 900 end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def kill(player_number, state) do
    player = Map.get(state.players, player_number)

    updated_player =
      Map.update!(player, :alive, fn _x -> false end)
      |> Map.update!(:position, fn _x -> state.alive_count end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def tick(state) do
    player = Map.get(state.players, state.player_number)

    updated_player = tick_player({state.player_number, player}, state)

    updated_players =
      Map.delete(state.players, state.player_number)
      |> Map.put(state.player_number, updated_player)

    %{
      state
      | players: updated_players,
        storm: state.storm + state.storm_speed,
        storm_speed: state.storm_speed + 0.05 / @tick
    }
  end

  def tick_player({_player_number, %{alive: false} = player_state} = _player, _state),
    do: player_state

  def tick_player(
        {player_number, %{y: y, y_speed: y_speed, x: x, x_speed: x_speed} = player_state},
        state
      ) do
    if state.storm > x do
      GameInstance.kill(player_number, state.uuid)
      GameServer.kill(player_number, state.server_uuid)
    end

    Task.start(fn -> check_collisions(player_number, {x, y}, state) end)

    updated_state = update_coords(player_state, x, y, x_speed, y_speed)

    updated_state
  end

  def update_coords(%{pipe: pipe} = player_state, x, y, x_speed, y_speed) when pipe - x > 0 do
    %{
      player_state
      | y: y + y_speed * 0.001,
        y_speed: y_speed,
        x: x + 0.5 * x_speed + 20,
        x_speed: x_speed + 0.35 / @tick
    }
  end

  def update_coords(player_state, x, y, x_speed, y_speed) when x < 30 do
    %{
      player_state
      | y: y,
        y_speed: y_speed,
        x: x + x_speed,
        x_speed: x_speed
    }
  end

  def update_coords(player_state, x, y, x_speed, y_speed) when y > 0 do
    %{
      player_state
      | y: y + y_speed * 0.05,
        y_speed: y_speed - 100 / @tick,
        x: x + x_speed,
        x_speed: x_speed + 0.2 / @tick
    }
  end

  def update_coords(player_state, x, y, x_speed, y_speed) do
    %{
      player_state
      | y: y + y_speed * 0.03,
        y_speed: y_speed + 80 / @tick,
        x: x + 0.5 * x_speed,
        x_speed: x_speed + 0.12 / @tick
    }
  end

  def check_collisions(player_number, {x, y}, %{game_map: map, uuid: uuid} = state) do
    {x, y}
    |> check_pipes(map.pipes)
    |> case do
      true ->
        GameInstance.pipe(player_number, uuid)

      false ->
        {x, y}
        |> check_trees(map.trees)
        |> case do
          true ->
            GameInstance.slow(player_number, 0.2, uuid)

          false ->
            nil
        end
    end
  end

  def check_trees({x, y}, trees) do
    Enum.any?(trees, fn {tree_x, tree_y} ->
      tree_x - round(x) <= 50 && tree_x - x >= -50 && y - tree_y < 0
    end)
  end

  def check_pipes({x, y}, pipes) do
    Enum.any?(pipes, fn {pipe_x, pipe_y} ->
      pipe_x - round(x) <= 25 && pipe_x - round(x) >= -10 && pipe_y - round(y) <= 15 &&
        pipe_y - round(y) >= -15

      # tree_x - round(x) <= 5 && tree_x - x >= -5 && (y - tree_y < 0 || y - tree_y > 40)
    end)
  end

  def generate_map() do
    trees = generate_trees([{500, 25}], 500)
    pipes = generate_pipes([{2500, 60}], 2500)
    %{trees: trees, pipes: pipes}
  end

  def generate_trees(trees_so_far, total_x) do
    if total_x >= 50000 do
      Enum.reverse(trees_so_far)
    else
      new_tree_x = total_x + Enum.random(300..1300)
      new_tree_y = Enum.random(12..80)
      new_tree = {new_tree_x, new_tree_y}
      generate_trees([new_tree | trees_so_far], new_tree_x)
    end
  end

  defp generate_pipes(pipes_so_far, total_x) do
    if total_x >= 50000 do
      Enum.reverse(pipes_so_far)
    else
      new_pipe_x = total_x + Enum.random(2000..4000)
      new_pipe_y = Enum.random(10..80)
      new_pipe = {new_pipe_x, new_pipe_y}
      generate_pipes([new_pipe | pipes_so_far], new_pipe_x)
    end
  end
end
