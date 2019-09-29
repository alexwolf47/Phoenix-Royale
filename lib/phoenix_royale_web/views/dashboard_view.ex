defmodule PhoenixRoyaleWeb.DashboardView do
  use PhoenixRoyaleWeb, :view

  def determine_level(experience) do
    cond do
      experience < 5000 -> 1
      experience < 11000 -> 2
      experience < 18000 -> 3
      experience < 26000 -> 4
      experience < 35000 -> 5
      experience < 48000 -> 6
      experience < 63500 -> 7
      experience < 73000 -> 8
      experience < 85000 -> 9
      experience < 99999 -> 10
      experience < 120_000 -> 11
      experience < 150_000 -> 12
      experience < 200_000 -> 13
      experience < 250_000 -> 14
      experience < 300_000 -> 15
      true -> 100
    end
  end

  def win_percentage(%{wins: wins, multiplayer_games_played: multiplayer_games_played}) do
    Float.round(wins/multiplayer_games_played, 1) * 100
  end
end
