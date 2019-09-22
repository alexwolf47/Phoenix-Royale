defmodule PhoenixRoyale.GameServer do
  use GenServer
  alias PhoenixRoyale.{Game, GameInstance, GameSettings, GameMap}

  defmodule GameState do
    defstruct server_status: :need_players,
              uuid: nil,
              start_countdown: 12,
              game_map: %{},
              player_count: 0,
              zzalive_count: 0,
              dead_players: [],
              players: %{},
              player_list: [],
              max_players: nil,
              winner: nil
  end

  def start_link(game_uuid, server_size) do
    game_map = GameMap.generate_map()

    GenServer.start_link(
      __MODULE__,
      %GameState{uuid: game_uuid, game_map: game_map, max_players: server_size},
      name: {:global, game_uuid}
    )
  end

  def init(server) do
    :timer.send_interval(1000 * 60 * 5, self(), :close)
    :timer.send_after(1000, self(), :lobby_timer)
    {:ok, server}
  end

  def state(game_uuid) do
    GenServer.call({:global, game_uuid}, :state)
  end

  def info(game_uuid) do
    GenServer.call({:global, game_uuid}, :info)
  end

  def update_players(game_uuid, updated_players) do
    GenServer.cast({:global, game_uuid}, {:update_players, updated_players})
  end

  def join(%PhoenixRoyale.Account{} = account, %PhoenixRoyale.Player{} = player, game_uuid) do
    GenServer.call({:global, game_uuid}, {:join, account, player})
  end

  def kill(player_number, server_uuid) do
    GenServer.cast({:global, server_uuid}, {:kill, player_number})
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:info, _from, state) do
    {:reply, {state.server_status, state.zzalive_count}, state}
  end

  def handle_call({:join, account, %{uuid: uuid} = player}, _, %{uuid: server_uuid} = state) do
    players = Map.put(state.players, state.player_count + 1, player)
    gameid = server_uuid <> "-" <> uuid

    status = check_full_status(state)
    next_player_number = state.player_count + 1

    GameInstance.start_link(
      server_uuid,
      gameid,
      state.game_map,
      account,
      next_player_number,
      players,
      status
    )

    new_state = %{
      state
      | player_count: next_player_number,
        zzalive_count: next_player_number,
        players: players,
        player_list: [player.name | state.player_list],
        server_status: status
    }

    if new_state.server_status == :full do
      PhoenixRoyale.GameCoordinator.start_game(server_uuid)
      p1_uuid = Map.get(new_state.players, 1).uuid
      p1_gameid = server_uuid <> "-" <> p1_uuid
      GameInstance.waterfall(p1_gameid, 1, new_state.players, new_state.zzalive_count)
    end

    {:reply, {server_uuid, gameid}, new_state}
  end

  defp check_full_status(state) do
    if state.player_count >= state.max_players - 1 do
      :full
    else
      :need_players
    end
  end

  def handle_cast({:kill, player_number}, %{zzalive_count: 1} = state) do
    winner = Map.get(state.players, player_number)
    {:noreply, %{state | zzalive_count: 0, server_status: :game_over, winner: winner}}
  end

  def handle_cast(
        {:kill, player_number},
        %{dead_players: dead_players, zzalive_count: zzalive_count} = state
      ) do
    unless Enum.any?(dead_players, fn pn -> pn == player_number end) do
      {:noreply,
       %{state | dead_players: [player_number | dead_players], zzalive_count: zzalive_count - 1}}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:update_players, updated_players}, state) do
    gameuuid = find_p1_gameid(state)

    GameInstance.waterfall(gameuuid, 1, updated_players, state.zzalive_count)
    {:noreply, %{state | players: updated_players}}
  end

  defp find_p1_gameid(state) do
    p1 = Map.get(state.players, 1)
    state.uuid <> "-" <> p1.uuid
  end

  def handle_info(:lobby_timer, state) do
    if state.start_countdown > 0 && state.server_status != :full do
      :timer.send_after(1000, self(), :lobby_timer)
      {:noreply, %{state | start_countdown: state.start_countdown - 1}}
    else
      PhoenixRoyale.GameCoordinator.start_game(state.uuid)
      p1_uuid = Map.get(state.players, 1).uuid
      p1_gameid = state.uuid <> "-" <> p1_uuid

      GameInstance.waterfall(p1_gameid, 1, state.players, state.zzalive_count)
      {:noreply, %{state | start_countdown: :started, server_status: :full}}
    end
  end

  def handle_info(:close, state) do
    {:stop, :normal, state}
  end
end
