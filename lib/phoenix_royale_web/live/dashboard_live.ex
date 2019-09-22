defmodule PhoenixRoyaleWeb.DashboardLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.Account

  def render(assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.DashboardView, "index.html", assigns)
  end

  def mount(session, socket) do
    account = Account.by_id(session.account_id)
    {:ok, assign(socket, account_id: session.account_id, account: account)}
  end

  def handle_event("logout", _arg, socket) do
    {:noreply, socket}
  end
end
