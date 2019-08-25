defmodule PhoenixRoyale.GameCoordinator do
  use GenServer
  alias PhoenixRoyale.{GameServer, Player}

  @server_name {:global, __MODULE__}

  defmodule GameCoordinator do
    defstruct need_players: %{},
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

  def finish_game(game_uuid) do
    GenServer.cast(@server_name, {:finish_game, game_uuid})
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:start_game, game_uuid}, state) do
    {:ok, game} = Map.fetch(state.need_players, game_uuid)
    need_players = Map.drop(state.need_players, [game_uuid])
    updated_full_games = Map.put(state.full_games, game_uuid, game)

    new_state = %{state | need_players: need_players, full_games: updated_full_games}
    {:noreply, new_state}
  end

  def handle_cast({:finish_game, game_uuid}, state) do
    updated_full_games = Map.drop(state.full_games, [game_uuid])

    new_state = %{state | full_games: updated_full_games}
    {:noreply, new_state}
  end

  ## If a player searches whilst there are no servers waiting for players, we start a new one.
  ## We then add the player as player 1 in this server.
  ## And update the list of games looking for players.

  def handle_call({:find_game, name}, {pid, _ref} = _from, %{need_players: games} = state)
      when map_size(games) == 0 do
    new_game_uuid = UUID.uuid4()
    {:ok, new_game_pid} = GameServer.start_link(new_game_uuid)

    player = %Player{name: name, pid: pid, uuid: UUID.uuid4()}
    gameid = GameServer.join(player, new_game_uuid)

    new_state = %{state | need_players: %{new_game_uuid => %{pid: new_game_pid}}}
    {:reply, gameid, new_state}
  end

  def handle_call({:find_game, name}, {pid, _ref} = _from, %{need_players: games} = state) do
    game_uuid = Enum.at(Map.keys(games), 0)

    player = %Player{name: name, pid: pid, uuid: UUID.uuid4()}
    gameid = GameServer.join(player, game_uuid)

    {:reply, gameid, state}
  end
end
