defmodule PhoenixRoyale.GameServer do
  use GenServer
  alias PhoenixRoyale.{Game, GameInstance, GameSettings}

  defmodule GameState do
    defstruct server_status: :need_players,
              uuid: nil,
              game_map: %{},
              player_count: 0,
              alive_count: 0,
              players: %{}
  end

  def start_link(game_uuid) do
    game_map = Game.generate_map()

    GenServer.start_link(__MODULE__, %GameState{uuid: game_uuid, game_map: game_map},
      name: {:global, game_uuid}
    )
  end

  def init(server) do
    :timer.send_interval(1000 * 60 * 2, self(), :close)
    {:ok, server}
  end

  def state(game_uuid) do
    GenServer.call({:global, game_uuid}, :state)
  end

  def update_players(game_uuid, updated_players) do
    GenServer.cast({:global, game_uuid}, {:update_players, updated_players})
  end

  def join(%PhoenixRoyale.Player{} = player, game_uuid) do
    GenServer.call({:global, game_uuid}, {:join, player})
  end

  def kill(player_number, game_uuid) do
    GenServer.cast({:global, game_uuid}, {:kill, player_number})
  end

  def handle_cast({:update_players, updated_players}, state) do
    # IO.inspect(new_state, label: "NEWNEWNNEWN STATE")
    p1 = Map.get(state.players, 1)
    gameuuid = state.uuid <> "-" <> p1.uuid
    new_state = %{state | players: updated_players}
    :timer.sleep(GameSettings.tick_interval())
    GameInstance.waterfall(gameuuid, 1, updated_players)
    {:noreply, new_state}
  end

  def handle_info(:close, state) do
    {:stop, :normal, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, player}, _from, state) do
    number_of_players = map_size(state.players)
    players = Map.put(state.players, number_of_players + 1, player)

    serverid = state.uuid
    gameid = state.uuid <> "-" <> player.uuid

    status =
      if number_of_players > 0 do
        PhoenixRoyale.GameCoordinator.start_game(serverid)
        :full
      else
        :need_players
      end

    player_game =
      GameInstance.start_link(
        serverid,
        gameid,
        state.game_map,
        number_of_players + 1,
        players,
        state.player_count + 1,
        status
      )

    new_state = %{
      state
      | player_count: state.player_count + 1,
        alive_count: state.alive_count + 1,
        players: players,
        server_status: status
    }

    p1uuid = Map.get(new_state.players, 1).uuid
    p1gameid = state.uuid <> "-" <> p1uuid

    if new_state.server_status == :full do
      GameInstance.waterfall(p1gameid, 1, new_state.players)
    end

    {:reply, {serverid, gameid}, new_state}
  end

  def handle_cast({:kill, player_number}, state), do: Game.kill(player_number, state)
end
