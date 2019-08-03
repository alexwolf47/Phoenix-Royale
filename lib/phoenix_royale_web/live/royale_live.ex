defmodule PhoenixRoyaleWeb.RoyaleLive do
  use Phoenix.LiveView


  def render(assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.GameView, "game.html", assigns)
  end

  def mount(_session, socket) do

    {:ok, socket}
  end

end
