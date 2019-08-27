defmodule PhoenixRoyaleWeb.DashboardLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.DashboardView, "index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, socket}
  end

  def handle_event("logout", _arg, socket) do
    {:noreply, socket}
  end
end
