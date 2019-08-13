defmodule PhoenixRoyale.GameInstance do
  use GenServer
  alias PhoenixRoyale.{Game, GameServer, GameInstance}

  defmodule GameInstanceState do
    defstruct server_status: :need_players,
              server_uuid: nil,
              uuid: nil,
              countdown: nil,
              game_map: %{},
              player_count: 0,
              alive_count: nil,
              players: %{},
              storm: -1000,
              storm_speed: 8,
              player_number: nil
  end

  def start_link(server_uuid, game_uuid, map, player_number, players, player_count, status) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(
      __MODULE__,
      %GameInstanceState{
        server_uuid: server_uuid,
        uuid: game_uuid,
        game_map: map,
        player_number: player_number,
        players: players,
        player_count: player_count,
        server_status: status
      },
      name: {:global, game_uuid}
    )
  end

  def init(server) do
    :timer.send_after(25, self(), :tick)
    :timer.send_interval(1000 * 60 * 2, self(), :close)
    {:ok, server}
  end

  @doc "allows the status of the server to be queried - client interface"

  def state(game_uuid) do
    GenServer.call({:global, game_uuid}, :state)
  end

  def waterfall(game_uuid, player_number, players) do
    # IO.puts("waterfall public")
    # IO.inspect({game_uuid, player_number, players}, label: "game uuid of waterfall")
    GenServer.cast({:global, game_uuid}, {:waterfall, player_number, players})
  end

  def jump(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:jump, player_number})
  end

  def slow(player_number, value, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:slow, player_number, value})
  end

  def kill(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:kill, player_number})
  end

  def handle_info(:close, state) do
    {:stop, :normal, state}
  end

  def handle_info(:tick, %{server_status: :playing, alive_count: 0} = state) do
    # IO.inspect(state, label: "state on tick")
    :timer.send_after(25, self(), :tick)
    {:noreply, %{state | server_status: :game_over}}
  end

  def handle_info(:tick, %{server_status: :playing} = state) do
    # IO.inspect(state, label: "state on tick")
    :timer.send_after(25, self(), :tick)
    {:noreply, Game.tick(state)}
  end

  def handle_info(:tick, %{server_status: :full} = state) do
    # IO.inspect(state, label: "state on tick")
    :timer.send_after(25, self(), :tick)
    PhoenixRoyale.GameCoordinator.start_game(state.uuid)

    {:noreply,
     %{
       state
       | server_status: :countdown,
         countdown: 3000,
         alive_count: map_size(state.players)
     }}
  end

  def handle_info(:tick, %{server_status: :countdown, countdown: countdown} = state)
      when countdown > 0 do
    # IO.inspect(state, label: "state on tick")
    :timer.send_after(25, self(), :tick)
    {:noreply, %{state | countdown: state.countdown - 50}}
  end

  def handle_info(:tick, %{server_status: :countdown} = state) do
    # IO.inspect(state, label: "state on tick")
    :timer.send_after(25, self(), :tick)
    {:noreply, %{state | server_status: :playing}}
  end

  def handle_info(:tick, %{server_status: :need_players} = state) do
    # IO.inspect(state, label: "state on tick")
    game_status = GameServer.state(state.server_uuid).server_status
    :timer.send_after(25, self(), :tick)
    {:noreply, %{state | server_status: game_status}}
  end

  def handle_info(:tick, %{server_status: :game_over} = state) do
    :timer.send_interval(1000 * 4, self(), :close)
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:jump, player_number}, state), do: Game.jump(player_number, state)

  def handle_cast({:slow, player_number, value}, state),
    do: Game.slow(player_number, value, state)

  def handle_cast({:kill, player_number}, state), do: Game.kill(player_number, state)

  # def handle_cast({:waterfall, wplayer, updated_players}, state), do: {:noreply, state}

  def handle_cast({:waterfall, wplayer, updated_players}, state) do
    # IO.puts("WATERFALLING***
    # ***")
    # IO.inspect(updated_players, label: "state in waterfall")

    if wplayer == state.player_number do
      # IO.puts("waterfalling for player #{wplayer}")
      # IO.inspect(state.players, label: "waterfall players")
      # IO.inspect(Map.get(state.players, state.player_number + 1), label: "Case sattement")
      # :timer.sleep(20000)

      case Map.get(updated_players, state.player_number + 1) do
        nil ->
          GameServer.update_players(state.server_uuid, state.players)
          this_player = Map.get(state.players, state.player_number)

          update1 = Map.delete(updated_players, wplayer)
          waterfalled_players = Map.put(update1, wplayer, this_player)
          new_state = %{state | players: waterfalled_players}
          {:noreply, new_state}

        player ->
          # IO.puts("waterfalling to next player")

          this_player = Map.get(state.players, state.player_number)

          update1 = Map.delete(updated_players, wplayer)
          waterfalled_players = Map.put(update1, wplayer, this_player)

          player_game = elem(String.split_at(state.uuid, 37), 0) <> player.uuid

          GameInstance.waterfall(player_game, state.player_number + 1, waterfalled_players)
          new_state = %{state | players: waterfalled_players}
          {:noreply, new_state}
      end
    else
      {:noreply, state}
    end
  end
end
