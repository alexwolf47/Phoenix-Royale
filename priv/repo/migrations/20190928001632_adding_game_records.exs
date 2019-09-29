defmodule PhoenixRoyale.Repo.Migrations.AddingGameRecords do
  use Ecto.Migration

  def change do
    create table(:game_records) do
      add :winner, :string
      add :player_count, :integer

      timestamps()
    end
  end
end
