defmodule PhoenixRoyaleWeb.DashboardLive do
  use Phoenix.LiveView
  alias PhoenixRoyale.{Account, GameStats, GameChat, GameRecord}

  def render(assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.DashboardView, "index.html", assigns)
  end

  def mount(session, socket) do
    account = Account.by_id(session.account_id)
    :timer.send_after(3000, self(), :update)
    :timer.send_after(500, self(), :chat_update)
    stats = GameStats.fetch_stats()
    live_games = GameStats.live_games()
    chat_messages = GameChat.state().messages
    leaderboard_stats = GameRecord.order_by_account_wins()

    {:ok,
     assign(socket,
       account_id: session.account_id,
       account: account,
       stats: stats,
       live_games: live_games,
       chat_messages: chat_messages,
       leaderboard: leaderboard_stats
     )}
  end

  def handle_event("logout", _arg, socket) do
    {:noreply, socket}
  end

  def handle_event("new_message", %{"message" => message}, socket) do
    GameChat.new_message(socket.assigns.account.name, message)
    {:noreply, assign(socket, chat_messages: GameChat.state().messages)}
  end

  def handle_info(:update, socket) do
    :timer.send_after(3000, self(), :update)
    stats = GameStats.fetch_stats()
    live_games = GameStats.live_games()
    {:noreply, assign(socket, stats: stats, live_games: live_games)}
  end

  def handle_info(:chat_update, socket) do
    :timer.send_after(500, self(), :chat_update)
    {:noreply, assign(socket, chat_messages: GameChat.state().messages)}
  end
end
