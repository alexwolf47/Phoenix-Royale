defmodule PhoenixRoyale.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :name, :string
      add :unique_id, :string
      add :experience, :integer
      add :wins, :integer
      add :games_played, :integer

      timestamps()
    end
  end
end
