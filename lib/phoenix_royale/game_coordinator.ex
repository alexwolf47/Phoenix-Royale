defmodule PhoenixRoyale.GameCoordinator do
  use GenServer
  alias PhoenixRoyale.{GameServer, Player}

  @server_name {:global, __MODULE__}

  defmodule GameCoordinator do
    defstruct unstarted_games: %{},
              full_games: %{},
              players: %{}
  end

  def start_link(_init_args) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, %GameCoordinator{}, name: @server_name)
  end

  def init(server) do
    {:ok, server}
  end

  def state() do
    GenServer.call(@server_name, :state)
  end

  def find_game(name) do
    GenServer.call(@server_name, {:find_game, name})
  end

  def start_game(game_uuid) do
    GenServer.cast(@server_name, {:start_game, game_uuid})
  end

  def handle_call(:state, _from, state) do
    IO.inspect(state)
    {:reply, state, state}
  end

  def handle_cast({:start_game, game_uuid}, state) do
    # game = Map.fetch(state.unstarted_games, game_uuid)
    # unstarted_games = Map.delete(state.unstarted_games, game_uuid)
    new_state = %{state | unstarted_games: %{}}
    {:noreply, new_state}
  end

  def handle_call({:find_game, name}, {pid, _ref} = _from, %{unstarted_games: games} = state)
      when map_size(games) == 0 do
    new_game_uuid = UUID.uuid4()
    {:ok, new_game_pid} = GameServer.start_link(new_game_uuid)

    player = %Player{name: name, pid: pid}
    GameServer.join(player, new_game_uuid)

    IO.puts("game coordinator!!")

    new_state = %{state | unstarted_games: %{new_game_uuid => %{pid: new_game_pid}}}
    {:reply, new_game_uuid, new_state}
  end

  def handle_call({:find_game, name}, {pid, _ref} = _from, %{unstarted_games: games} = state) do
    IO.inspect(state, label: "STATE IN GAME CO")
    game_uuid = Enum.at(Map.keys(games), 0)

    player = %Player{name: name, pid: pid}
    GameServer.join(player, game_uuid)

    {:reply, game_uuid, state}
  end
end
