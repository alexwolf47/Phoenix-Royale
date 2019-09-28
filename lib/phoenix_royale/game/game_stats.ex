defmodule PhoenixRoyale.GameStats do
  alias PhoenixRoyale.{Account, GameCoordinator, GameRecord, GameServer}

  def fetch_stats() do
    %{
      current_games: current_games(),
      total_games_played: total_games_played(),
      unique_players: unique_players(),
      playing_now: playing_now()
    }
  end

  def current_games() do
    GameCoordinator.state().full_games
    |> Map.to_list()
    |> Enum.count()
  end

  def total_games_played() do
    GameRecord.get_all()
    |> Enum.count()
  end

  def unique_players() do
    Account.get_all()
    |> Enum.count()
  end

  def playing_now() do
    GameCoordinator.state().players
    |> Map.to_list()
    |> Enum.count()
  end

  def live_games do
    GameCoordinator.state().full_games
    |> Map.to_list()
    |> Enum.map(fn {uuid, _} ->
      GameServer.state(uuid)
    end)
  end
end
