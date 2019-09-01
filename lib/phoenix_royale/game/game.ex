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

    if player.pipe > 0 do
      {:noreply, state}
    else
      updated_player = Map.update!(player, :x_speed, fn x -> x * value end)

      updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
      {:noreply, %{state | players: updated_players}}
    end
  end

  def pipe(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :pipe, fn _x -> player.x + 500 end)

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
        storm_speed: state.storm_speed + 0.05 / @tick,
        tick: state.tick + 1
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

    # Task.start(fn -> check_collisions(player_number, {x, y}, state) end)

    updated_state = update_coords(player_state, x, y, x_speed, y_speed)

    updated_state
  end

  def update_coords(%{pipe: pipe} = player_state, x, y, x_speed, y_speed) when pipe - x > 0 do
    %{
      player_state
      | y: y + y_speed * 0.02,
        y_speed: y_speed,
        x: x + 0.8 * x_speed + 20,
        x_speed: x_speed + 0.3 / @tick
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
        x_speed: x_speed + 0.06 / @tick
    }
  end

  def update_coords(player_state, x, y, x_speed, y_speed) do
    %{
      player_state
      | y: y + y_speed * 0.03,
        y_speed: y_speed + 80 / @tick,
        x: x + 0.5 * x_speed,
        x_speed: x_speed + 0.04 / @tick
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
            GameInstance.slow(player_number, 0.995, uuid)

          false ->
            nil
        end
    end
  end

  def check_trees({x, y}, trees) do
    Enum.any?(trees, fn {tree_x, tree_y, length} ->
      tree_x - round(x) <= 0 && tree_x - x >= -1 * length && (y - tree_y < 0 || y - tree_y > 40)
    end)
  end

  def check_pipes({x, y}, pipes) do
    Enum.any?(pipes, fn {pipe_x, pipe_y} ->
      pipe_x - round(x) <= 0 && pipe_x - round(x) >= -30 && pipe_y - round(y) <= 5 &&
        pipe_y - round(y) >= -5
    end)
  end

  def generate_map() do
    trees = generate_trees([{500, 25, 100}], 500)
    pipes = generate_pipes([], 2500)
    %{trees: trees, pipes: pipes}
  end

  def generate_trees(trees_so_far, total_x) do
    if total_x >= 50000 do
      Enum.reverse(trees_so_far)
    else
      new_tree_x = total_x + Enum.random(300..600)
      new_tree_y = Enum.random(-30..90)
      new_tree_length = Enum.random(30..280)
      new_tree = {new_tree_x, new_tree_y, new_tree_length}
      generate_trees([new_tree | trees_so_far], new_tree_x + new_tree_length)
    end
  end

  defp generate_pipes(pipes_so_far, total_x) do
    if total_x >= 50000 do
      Enum.reverse(pipes_so_far)
    else
      new_pipe_x = total_x + Enum.random(2000..4000)
      new_pipe_y = Enum.random(10..90)
      new_pipe = {new_pipe_x, new_pipe_y}
      generate_pipes([new_pipe | pipes_so_far], new_pipe_x)
    end
  end
end
