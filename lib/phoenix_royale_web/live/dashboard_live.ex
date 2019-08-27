defmodule PhoenixRoyaleWeb.DashboardLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.DashboardView, "index.html", assigns)
  end

  def mount(session, socket) do
    IO.inspect(session, label: "sessiom")
    {:ok, socket}
  end

  @spec handle_event(<<_::48>>, any, any) :: {:noreply, any}
  def handle_event("logout", _arg, socket) do
    {:noreply, socket}
  end
end
