defmodule PhoenixRoyale.GameServer do
  use GenServer
  alias PhoenixRoyale.Game

  defmodule GameState do
    defstruct server_status: :need_players,
              uuid: nil,
              countdown: nil,
              game_map: %{},
              player_count: 0,
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
    :timer.send_interval(20, self(), :tick)
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

  def jump(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:jump, player_number})
  end

  def slow(player_number, value, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:slow, player_number, value})
  end

  def kill(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:kill, player_number})
  end

  def handle_info(:tick, %{server_status: :playing} = state) do
    {:noreply, Game.tick(state)}
  end

  def handle_info(:tick, %{server_status: :full} = state) do
    PhoenixRoyale.GameCoordinator.start_game(state.uuid)

    {:noreply,
     %{state | server_status: :countdown, countdown: 3000, game_map: Game.generate_map()}}
  end

  def handle_info(:tick, %{server_status: :countdown, countdown: countdown} = state)
      when countdown > 0 do
    {:noreply, %{state | countdown: state.countdown - 20}}
  end

  def handle_info(:tick, %{server_status: :countdown} = state) do
    {:noreply, %{state | server_status: :playing}}
  end

  def handle_info(:tick, %{server_status: :need_players} = state) do
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, player}, _from, state) do
    number_of_players = map_size(state.players)
    players = Map.put(state.players, number_of_players + 1, player)

    status =
      if number_of_players > -1 do
        :full
      else
        :full
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
