defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.{GameCoordinator, GameServer, GameInstance, GameSettings}

  def render(assigns) do
    case assigns.game_state do
      nil ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "landing.html", assigns)

      %{server_status: :need_players} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "lobby.html", assigns)

      %{server_status: :game_over} ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "dead.html", assigns)

      _ ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game.html", assigns)
    end
  end

  def mount(session, socket) do
    {:ok,
     assign(socket,
       account: session.account_name,
       game_state: nil,
       player_number: nil,
       dev: false,
       player_list: [],
       start_countdown: nil,
       tick: 0
     )}
  end

  def handle_info(:update_player_list, socket) do
    state = GameServer.state(socket.assigns.game_state.server_uuid)
    :timer.send_after(500, self(), :update_player_list)

    {:noreply,
     assign(socket, player_list: state.player_list, start_countdown: state.start_countdown)}
  end

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

  def handle_event("find_sp_game", _arg, socket) do
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

  def handle_event("jump", _arg, socket) do
    player_number = socket.assigns.player_number
    GameInstance.jump(player_number, socket.assigns.game_uuid)
    {:noreply, socket}
  end
end
