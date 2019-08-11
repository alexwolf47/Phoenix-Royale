defmodule PhoenixRoyale.GameServer do
  use GenServer
  alias PhoenixRoyale.Game

  defmodule GameState do
    defstruct server_status: :need_players,
              uuid: nil,
              countdown: nil,
              game_map: %{},
              player_count: 0,
              alive_count: nil,
              players: %{},
              storm: -1000,
              storm_speed: 10
  end

  def start_link(game_uuid) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, %GameState{uuid: game_uuid}, name: {:global, game_uuid})
  end

  def init(server) do
    :timer.send_after(33, self(), :tick)
    :timer.send_interval(1000 * 60 * 10, self(), :close)
    {:ok, server}
  end

  @doc "allows the status of the server to be queried - client interface"

  def state(game_uuid) do
    GenServer.call({:global, game_uuid}, :state)
  end

  @doc "allows a player to join the server - client interface"

  def join(%PhoenixRoyale.Player{} = player, game_uuid) do
    GenServer.call({:global, game_uuid}, {:join, player})
  end

  def update_player({player_number, updated_state}, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:update_player, player_number, updated_state})
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

  def handle_cast({:update_player, player_number, updated_player_state}, state) do
    updated_players =
      state.players
      |> Map.delete(player_number)
      |> Map.put(player_number, updated_player_state)

    {:noreply, %{state | players: updated_players}}
  end

  def handle_info(:close, state) do
    {:stop, :normal, state}
  end

  def handle_info(:tick, %{server_status: :playing, alive_count: 0} = state) do
    :timer.send_after(33, self(), :tick)
    {:noreply, %{state | server_status: :game_over}}
  end

  def handle_info(:tick, %{server_status: :playing} = state) do
    :timer.send_after(33, self(), :tick)
    {:noreply, Game.tick(state)}
  end

  def handle_info(:tick, %{server_status: :full} = state) do
    :timer.send_after(33, self(), :tick)
    PhoenixRoyale.GameCoordinator.start_game(state.uuid)

    {:noreply,
     %{
       state
       | server_status: :countdown,
         countdown: 3000,
         alive_count: map_size(state.players),
         game_map: Game.generate_map()
     }}
  end

  def handle_info(:tick, %{server_status: :countdown, countdown: countdown} = state)
      when countdown > 0 do
    :timer.send_after(33, self(), :tick)
    {:noreply, %{state | countdown: state.countdown - 50}}
  end

  def handle_info(:tick, %{server_status: :countdown} = state) do
    :timer.send_after(33, self(), :tick)
    {:noreply, %{state | server_status: :playing}}
  end

  def handle_info(:tick, %{server_status: :need_players} = state) do
    :timer.send_after(33, self(), :tick)
    {:noreply, state}
  end

  def handle_info(:tick, %{server_status: :game_over} = state) do
    :timer.send_interval(1000 * 4, self(), :close)
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, player}, _from, state) do
    number_of_players = map_size(state.players)
    players = Map.put(state.players, number_of_players + 1, player)

    status =
      if number_of_players > 0 do
        :full
      else
        :need_players
      end

    new_state = %{
      state
      | player_count: state.player_count + 1,
        players: players,
        server_status: status
    }

    {:reply, new_state, new_state}
  end

  def handle_cast({:jump, player_number}, state), do: Game.jump(player_number, state)

  def handle_cast({:slow, player_number, value}, state),
    do: Game.slow(player_number, value, state)

  def handle_cast({:kill, player_number}, state), do: Game.kill(player_number, state)
end
