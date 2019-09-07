defmodule PhoenixRoyale.GameInstance do
  use GenServer
  alias PhoenixRoyale.{Game, GameServer, GameInstance, GameSettings}

  defmodule GameInstanceState do
    defstruct server_status: :need_players,
              server_uuid: nil,
              uuid: nil,
              countdown: 3000,
              game_map: %{},
              player_count: 0,
              alive_count: nil,
              players: %{},
              storm: -1000,
              storm_speed: 6,
              player_number: nil,
              tick: 0
  end

  @tick GameSettings.tick_interval()

  def start_link(server_uuid, game_uuid, map, player_number, players, status) do
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
        player_count: player_number,
        server_status: status
      },
      name: {:global, game_uuid}
    )
  end

  def init(server) do
    :timer.send_after(@tick, self(), :tick)
    :timer.send_interval(1000 * 60 * 5, self(), :close)
    {:ok, server}
  end

  @doc "allows the status of the server to be queried - client interface"

  def state(game_uuid) do
    GenServer.call({:global, game_uuid}, :state)
  end

  def waterfall(game_uuid, player_number, players, alive_count) do
    GenServer.cast({:global, game_uuid}, {:waterfall, player_number, players, alive_count})
  end

  def jump(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:jump, player_number})
  end

  def slow(player_number, value, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:slow, player_number, value})
  end

  def block(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:block, player_number})
  end

  def pipe(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:pipe, player_number})
  end

  def kill(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:kill, player_number})
  end

  def handle_info(:tick, %{server_status: :playing, alive_count: 0} = state) do
    :timer.send_after(@tick, self(), :tick)
    {:noreply, %{state | server_status: :game_over}}
  end

  def handle_info(:tick, %{server_status: :playing} = state) do
    :timer.send_after(@tick, self(), :tick)
    {:noreply, Game.tick(state)}
  end

  def handle_info(:tick, %{server_status: :full} = state) do
    :timer.send_after(@tick, self(), :tick)

    {:noreply, %{state | server_status: :countdown, player_count: state.alive_count}}
  end

  def handle_info(:tick, %{server_status: :countdown, countdown: countdown} = state)
      when countdown > 0 do
    :timer.send_after(@tick, self(), :tick)
    {:noreply, %{state | countdown: state.countdown - 50}}
  end

  def handle_info(:tick, %{server_status: :countdown} = state) do
    :timer.send_after(@tick, self(), :tick)
    # :timer.send_after(GameSettings.server_update_interval(), self(), :server_update)
    {:noreply, %{state | server_status: :playing}}
  end

  def handle_info(:tick, %{server_status: :need_players} = state) do
    game_status = GameServer.state(state.server_uuid).server_status
    :timer.send_after(25, self(), :tick)
    {:noreply, %{state | server_status: game_status}}
  end

  def handle_info(:tick, %{server_status: :game_over} = state) do
    :timer.send_interval(GameSettings.postgame_screen_timeout(), self(), :close)
    {:noreply, state}
  end

  def handle_info(:server_update, state) do
    :timer.send_after(GameSettings.server_update_interval(), self(), :server_update)
    {status, count} = GameServer.info(state.server_uuid)

    {:noreply, %{state | server_status: status, alive_count: count}}
  end

  def handle_info(:close, state) do
    {:stop, :normal, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:jump, player_number}, state), do: Game.jump(player_number, state)

  def handle_cast({:slow, player_number, value}, state),
    do: Game.slow(player_number, value, state)

  def handle_cast({:block, player_number}, state),
    do: Game.block(player_number, state)

  def handle_cast({:pipe, player_number}, state),
    do: Game.pipe(player_number, state)

  def handle_cast({:kill, player_number}, state), do: Game.kill(player_number, state)

  def handle_cast({:waterfall, next_player_number, updated_players, alive_count}, state) do
    case Map.get(updated_players, state.player_number + 1) do
      nil ->
        GameServer.update_players(state.server_uuid, state.players)
        this_player = Map.get(state.players, state.player_number)

        {:noreply,
         %{
           state
           | alive_count: alive_count,
             players: Map.put(updated_players, next_player_number, this_player)
         }}

      player ->
        this_player = Map.get(state.players, state.player_number)
        waterfalled_players = Map.put(updated_players, next_player_number, this_player)
        player_game = state.server_uuid <> "-" <> player.uuid

        GameInstance.waterfall(
          player_game,
          state.player_number + 1,
          waterfalled_players,
          alive_count
        )

        new_state = %{state | players: waterfalled_players, alive_count: alive_count}
        {:noreply, new_state}
    end
  end
end
