defmodule PhoenixRoyale.Repo.Migrations.AddMultiplayerGamesToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :multiplayer_games_played, :integer
    end
  end
end
