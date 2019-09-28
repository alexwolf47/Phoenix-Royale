defmodule PhoenixRoyaleWeb.DashboardLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.{Account, GameStats, GameRecord}

  def render(assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.DashboardView, "index.html", assigns)
  end

  def mount(session, socket) do
    account = Account.by_id(session.account_id)
    :timer.send_after(3000, self(), :update)
    stats = GameStats.fetch_stats()
    live_games = GameStats.live_games()
    account_wins = GameRecord.get_account_wins(account.name)

    {:ok,
     assign(socket,
       account_id: session.account_id,
       account: account,
       stats: stats,
       live_games: live_games,
       account_wins: account_wins
     )}
  end

  def handle_event("logout", _arg, socket) do
    {:noreply, socket}
  end

  def handle_info(:update, socket) do
    :timer.send_after(3000, self(), :update)
    stats = GameStats.fetch_stats()
    live_games = GameStats.live_games()
    {:noreply, assign(socket, stats: stats, live_games: live_games)}
  end
end
