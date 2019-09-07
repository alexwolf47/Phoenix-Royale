defmodule PhoenixRoyale.Game do
  alias PhoenixRoyale.{GameServer, GameInstance, GameSettings, GameMap}

  @tick GameSettings.tick_rate()

  def jump(player_number, state) do
    player = Map.get(state.players, player_number)

    updated_player =
      if player.x > 30 do
        Map.update!(player, :y_speed, fn y_speed -> modify_y_speed(y_speed) end)
      else
        player
      end

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def modify_y_speed(y_speed) do
    round(y_speed * 0.6 + 50)
  end

  def slow(player_number, value, state) do
    player = Map.get(state.players, player_number)

    if player.pipe > 0 do
      {:noreply, state}
    else
      updated_player = Map.update!(player, :x_speed, fn x -> round(x * value) end)

      updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
      {:noreply, %{state | players: updated_players}}
    end
  end

  def block(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :x, fn _x -> round(player.x - player.x_speed) end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def pipe(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :pipe, fn _x -> round(player.x + 500) end)

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
        storm: round(state.storm + state.storm_speed),
        storm_speed: round(state.storm_speed + 0.05 / @tick),
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

    Task.start(fn -> check_collisions(player_number, {x, y}, state) end)

    updated_state = update_coords(player_state, x, y, x_speed, y_speed)

    updated_state
  end

  def update_coords(%{pipe: pipe} = player_state, x, y, x_speed, y_speed) when pipe - x > 0 do
    %{
      player_state
      | y: round(y + y_speed * 0.02),
        y_speed: y_speed,
        x: round(x + 0.8 * x_speed + 20),
        x_speed: round(x_speed + 0.3 / @tick)
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
      | y: round(y + y_speed * 0.05),
        y_speed: round(y_speed - 100 / @tick),
        x: round(x + x_speed),
        x_speed: round(x_speed + 0.06 / @tick)
    }
  end

  def update_coords(player_state, x, y, x_speed, y_speed) do
    %{
      player_state
      | y: round(y + y_speed * 0.03),
        y_speed: round(y_speed + 80 / @tick),
        x: round(x + 0.5 * x_speed),
        x_speed: round(x_speed + 0.04 / @tick)
    }
  end

  def player_zone_from_x(x) do
    Kernel.round(x / GameMap.zone_total() + 0.5)
  end

  def fetch_zone_map_from_x(map, x) do
    zone_number = player_zone_from_x(x)
    zone = String.to_atom("zone_#{zone_number}")
    Map.get(map, zone, [])
  end

  def check_collisions(player_number, {x, y}, %{game_map: map, uuid: uuid} = _state) do
    zone_map = fetch_zone_map_from_x(map, x)

    {x, y}
    |> check_pipes(filter(zone_map, :pipe))
    |> case do
      true ->
        GameInstance.pipe(player_number, uuid)

      false ->
        {x, y}
        |> check_trees(filter(zone_map, :tree))
        |> case do
          true ->
            GameInstance.kill(player_number, uuid)

          false ->
            nil
        end
    end
  end

  def filter(zone_map, object) do
    Enum.filter(zone_map, &(elem(&1, 0) == object))
  end

  def check_trees({x, y}, trees) do
    Enum.any?(trees, fn {:tree, tree_x, tree_y, length} ->
      tree_x - round(x) <= 0 && tree_x - x >= -1 * length && (y - tree_y < 0 || y - tree_y > 40)
    end)
  end

  def check_pipes({x, y}, pipes) do
    Enum.any?(pipes, fn {:pipe, pipe_x, pipe_y} ->
      pipe_x - round(x) <= 0 && pipe_x - round(x) >= -30 && pipe_y - round(y) <= 5 &&
        pipe_y - round(y) >= -5
    end)
  end
end
