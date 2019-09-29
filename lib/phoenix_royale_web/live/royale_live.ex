defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView

  alias PhoenixRoyale.{
    Account,
    GameCoordinator,
    GameChat,
    GameServer,
    GameInstance,
    GameStats,
    GameSettings
  }

  def render(assigns) do
    case assigns.game_state do
      nil ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game_choice.html", assigns)

      %{server_status: :need_players} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "lobby.html", assigns)

      %{server_status: :game_over} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game_over.html", assigns)

      _ ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game_v2.html", assigns)
    end
  end

  def mount(session, socket) do
    account = Account.by_id(session.account_id)

    :timer.send_after(1000, self(), :live_games_update)
    :timer.send_after(500, self(), :chat_update)

    {:ok,
     assign(socket,
       account_id: session.account_id,
       account: account,
       game_state: nil,
       game_settings: %{height: 800},
       player_number: nil,
       dev: false,
       player_list: [],
       start_countdown: nil,
       tick: 0,
       game_over: 100,
       live_games: GameStats.live_games(),
       global_chat_messages: GameChat.state().messages,
       game_needing_players: GameStats.games_waiting()
     )}
  end

  @spec handle_event(<<_::32, _::_*8>>, any, atom | %{assigns: atom | map}) :: {:noreply, any}
  def handle_event("find_game", _arg, socket) do
    {_serverid, gameid} = GameCoordinator.find_game(socket.assigns.account)
    game_state = GameInstance.state(gameid)
    :timer.send_after(GameSettings.tick_interval(), self(), :update)
    :timer.send_after(10, self(), :update_player_list)

    {:noreply,
     assign(socket,
       player_number: game_state.player_count,
       game_state: game_state,
       game_uuid: gameid
     )}
  end

  def handle_event("find_single_player_game", _arg, socket) do
    {_serverid, gameid} = GameCoordinator.single_player_game(socket.assigns.account)
    game_state = GameInstance.state(gameid)
    :timer.send_after(GameSettings.tick_interval(), self(), :update)
    :timer.send_after(10, self(), :update_player_list)

    {:noreply,
     assign(socket,
       player_number: game_state.player_count,
       game_state: game_state,
       game_uuid: gameid
     )}
  end

  def handle_event("jump", _arg, socket) do
    player_number = socket.assigns.player_number
    GameInstance.jump(player_number, socket.assigns.game_uuid)
    send(self(), :update)
    {:noreply, socket}
  end

  def handle_event("new_global_message", %{"message" => message}, socket) do
    GameChat.new_message(socket.assigns.account.name, message)
    {:noreply, assign(socket, global_chat_messages: GameChat.state().messages)}
  end

  def handle_info(:update_player_list, socket) do
    state = GameServer.state(socket.assigns.game_state.server_uuid)
    :timer.send_after(500, self(), :update_player_list)

    {:noreply,
     assign(socket, player_list: state.player_list, start_countdown: state.start_countdown)}
  end

  def handle_info(:update, socket) do
    updated_game_state = GameInstance.state(socket.assigns.game_uuid)
    player = Map.get(updated_game_state.players, socket.assigns.player_number)

    if player.alive || socket.assigns.game_state.server_status != :game_over do
      :timer.send_after(GameSettings.tick_interval(), self(), :update)

      {:noreply,
       assign(socket, game_state: updated_game_state, tick: socket.assigns.game_state.tick + 1)}
    else
      {:noreply, assign(socket, game_state: Map.put(updated_game_state, :dead, true))}
    end
  end

  def handle_info(:live_games_update, socket) do
    :timer.send_after(1000, self(), :live_games_update)
    live_games = GameStats.live_games()

    {:noreply,
     assign(socket,
       live_games: live_games,
       game_needing_players: GameStats.games_waiting()
     )}
  end

  def handle_info(:chat_update, socket) do
    :timer.send_after(500, self(), :chat_update)
    {:noreply, assign(socket, global_chat_messages: GameChat.state().messages)}
  end
end
