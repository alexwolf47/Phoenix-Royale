defmodule PhoenixRoyale.Repo.Migrations.AddingMaxDistance do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :max_distance, :integer, default: 0
    end
  end
end
