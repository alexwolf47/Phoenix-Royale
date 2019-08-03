defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.GameServer


  def render(assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game.html", assigns)
  end

  def mount(_session, socket) do

    {:ok, assign(socket, player_number: nil)}
  end


  def handle_event("join_game", %{"join" => %{"name" => name}}, socket) do

    ## Game server finder stuff would go here.. For now let's just make a GenServer
    GameServer.start_link("Hello World")

    GameServer.join(name)

    player_number = GameServer.state().player_count
    {:noreply, assign(socket, player_number: player_number)}
  end
end
