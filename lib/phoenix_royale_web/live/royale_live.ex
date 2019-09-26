defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.{Account, GameCoordinator, GameServer, GameInstance, GameSettings}

  def render(assigns) do
    case assigns.game_state do
      nil ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "landing.html", assigns)

      %{server_status: :need_players} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "lobby.html", assigns)

      %{server_status: :game_over} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "dead.html", assigns)

      _ ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game_v2.html", assigns)
    end
  end

  def mount(session, socket) do
    account = Account.by_id(session.account_id)

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
       game_over: 1000
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
      :timer.send_after(GameSettings.tick_interval(), self(), :game_over_update)

      {:noreply, assign(socket, game_state: Map.put(updated_game_state, :dead, true))}
    end
  end

  def handle_info(:game_over_update, socket) do
    cond do
      socket.assigns.game_over > 0 ->
        :timer.send_after(GameSettings.tick_interval(), self(), :game_over_update)
        {:noreply, assign(socket, game_over: socket.assigns.game_over - 1)}

      true ->
        {:noreply, socket}
    end
  end
end
