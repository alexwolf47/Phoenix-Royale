defmodule PhoenixRoyale.Game do
  alias PhoenixRoyale.{Account, GameServer, GameInstance, GameSettings, GameMap}

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

  def block(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :x, fn _x -> player.x - player.x_speed end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def pipe(player_number, state) do
    player = Map.get(state.players, player_number)
    updated_player = Map.update!(player, :pipe, fn _x -> player.x + 500 end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def kill(player_number, death_type, %{account: account} = state) do
    player = Map.get(state.players, player_number)
    experience_earned = player.x / 10

    multiplayer_games_played =
      case state.player_count do
        1 ->
          account.multiplayer_games_played

        _ ->
          account.multiplayer_games_played + 1
      end

    max_distance =
      if player.x > account.max_distance do
        round(player.x)
      else
        account.max_distance
      end

    Account.update(account, %{
      experience: round(account.experience + experience_earned),
      games_played: account.games_played + 1,
      max_distance: max_distance,
      multiplayer_games_played: multiplayer_games_played
    })

    updated_player =
      Map.update!(player, :alive, fn _x -> false end)
      |> Map.update!(:position, fn _x -> state.alive_count end)
      |> Map.update!(:death_type, fn _x -> death_type end)
      |> Map.update!(:storm_at_death, fn _x -> state.storm end)

    updated_players = Map.update!(state.players, player_number, fn _x -> updated_player end)
    {:noreply, %{state | players: updated_players}}
  end

  def remove_object_from_map(player_number, object, state) do
    player = Map.get(state.players, player_number)

    zone_map = fetch_zone_map_from_x(state.game_map, player.x)
    updated_zone_map = Enum.filter(zone_map, fn map_object -> map_object != object end)
    updated_game_map = update_zone_in_map(state.game_map, updated_zone_map, player.x)
    {:noreply, %{state | game_map: updated_game_map}}
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
        storm_speed: state.storm_speed + 0.28 / @tick,
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
      GameInstance.kill(player_number, :storm, state.uuid)
      GameServer.kill(player_number, state.server_uuid)
    end

    Task.start(fn -> check_collisions(player_number, {x, y}, state) end)

    update_coords(player_state, x, y, x_speed, y_speed)
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
      | y: y + y_speed * 0.035,
        y_speed: y_speed - 70 / @tick,
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

  def player_zone_from_x(x) do
    Kernel.round(x / GameMap.zone_total() + 0.5)
  end

  def fetch_zone_map_from_x(map, x) do
    zone_number = player_zone_from_x(x)
    zone = String.to_atom("zone_#{zone_number}")
    Map.get(map, zone, [])
  end

  def update_zone_in_map(game_map, updated_zone_map, player_x) do
    zone_number = player_zone_from_x(player_x)
    zone = String.to_atom("zone_#{zone_number}")
    Map.update!(game_map, zone, fn _ -> updated_zone_map end)
  end

  def check_collisions(player_number, {x, y}, %{game_map: map, uuid: uuid} = state) do
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
            # GameInstance.kill(player_number, uuid)
            {x, y}

          false ->
            {x, y}
        end
        |> check_lighthouses(filter(zone_map, :lighthouse))
        |> case do
          true ->
            GameInstance.kill(player_number, :collision, uuid)
            GameServer.kill(player_number, state.server_uuid)
            {x, y}

          false ->
            {x, y}
            |> check_comets(filter(zone_map, :comet))
            |> case do
              true ->
                GameInstance.kill(player_number, :comet, uuid)
                GameServer.kill(player_number, state.server_uuid)
                {x, y}

              false ->
                {x, y}
                |> check_elixirs(filter(zone_map, :elixir), player_number, uuid)
                |> case do
                  true ->
                    GameInstance.slow(player_number, 1.03, uuid)
                    {x, y}

                  false ->
                    {x, y}
                end
            end
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

  def check_lighthouses({x, y}, lighthouses) do
    Enum.any?(lighthouses, fn {:lighthouse, lighthouse_x, lighthouse_y} ->
      lighthouse_y - round(y) <= 20 && lighthouse_y - round(y) >= -20 &&
        lighthouse_x - round(x) <= 270 && lighthouse_x - round(x) >= 220
    end)
  end

  defp check_comets({x, y}, comets) do
    Enum.any?(comets, fn {:comet, comet_x, comet_y} ->
      comet_x - round(x) <= 20 && comet_x - round(x) >= -80 && comet_y - round(y) <= -15 &&
        comet_y - round(y) >= -25
    end)
  end

  defp check_elixirs({x, y}, elixirs, player_number, uuid) do
    Enum.any?(elixirs, fn {:elixir, elixir_x, elixir_y} = elixir ->
      if elixir_x - round(x) <= 0 && elixir_x - round(x) >= -50 && elixir_y - round(y) <= 7 &&
           elixir_y - round(y) >= -7 do
        GameInstance.pop_object_from_map(player_number, uuid, elixir)
        true
      else
        false
      end
    end)
  end
end
