defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.GameServer

  def render(assigns) do
    # IO.inspect(assigns.game_state, label: "game state")
    case assigns.game_state do
      nil -> Phoenix.View.render(PhoenixRoyaleWeb.GameView, "join.html", assigns)
      %{server_status: :full} = game_state ->
        Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game.html", assigns)
    end

  end

  def mount(_session, socket) do

    {:ok, assign(socket, game_state: nil, player_number: nil)}
  end

  def handle_info(:update, socket) do
    new_game_state = GameServer.state()
    {:noreply, assign(socket, game_state: new_game_state)}
  end


  def handle_event("jump", arg, socket) do
    player_number = socket.assigns.player_number
    GameServer.jump(player_number)
    {:noreply, socket}
  end

  def handle_event("join_game", %{"join" => %{"name" => name}}, socket) do

    ## Game server finder stuff would go here.. For now let's just make a GenServer
    GameServer.start_link("Hello World")

    GameServer.join(name)

    game_state = GameServer.state()

    # IO.inspect(game_state.server_status == :full, label: "server status")

    if game_state.server_status == :full do
      IO.puts("beingging updates")
      :timer.send_interval(25, self(), :update)
    end
    {:noreply, assign(socket, player_number: game_state.player_count, game_state: game_state)}
  end
end
