defmodule PhoenixRoyale.GameServer do
  use GenServer
  alias PhoenixRoyale.Game

  @server_name {:global, Server}

  defmodule GameState do
    defstruct server_status: :need_players,
              countdown: nil,
              game_map: %{},
              player_count: 0,
              players: %{}
  end

  defmodule Player do
    defstruct name: "",
              started: false,
              alive: true,
              pid: nil,
              y: 50,
              y_acc: 0,
              x: 0,
              x_acc: 5
  end

  def start_link(_init_args) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, %GameState{}, name: @server_name)
  end

  def init(server) do
    :timer.send_interval(20, self(), :tick)
    {:ok, server}
  end

  @doc "allows the status of the server to be queried - client interface"

  def state() do
    GenServer.call(@server_name, :state)
  end

  @doc "allows a player to join the server - client interface"

  def join(name) do
    GenServer.call(@server_name, {:join, name})
  end

  def jump(player_number) do
    GenServer.cast(@server_name, {:jump, player_number})
  end

  def kill(player_number) do
    GenServer.cast(@server_name, {:kill, player_number})
  end

  def handle_info(:tick, %{server_status: :playing} = state) do
    {:noreply, Game.tick(state)}
  end

  def handle_info(:tick, %{server_status: :full} = state) do
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

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, name}, {pid, _ref} = _from, state) do
    player = %Player{name: name, pid: pid}
    number_of_players = map_size(state.players)
    players = Map.put(state.players, number_of_players + 1, player)

    new_state = %{
      state
      | player_count: state.player_count + 1,
        players: players,
        server_status: :full
    }

    {:reply, "Player joined", new_state}
  end

  def handle_cast({:jump, player_number}, state), do: Game.jump(player_number, state)

  def handle_cast({:kill, player_number}, state), do: Game.kill(player_number, state)
end
