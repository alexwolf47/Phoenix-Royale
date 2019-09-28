defmodule PhoenixRoyale.GameRecord do
  use Ecto.Schema
  alias PhoenixRoyale.Repo
  import Ecto.Changeset

  schema "game_records" do
    field :winner, :string
    field :player_count, :integer

    timestamps()
  end

  def changeset(record, params \\ %{}) do
    record
    |> cast(params, [:winner, :player_count])
  end

  def new(game_state) do
    record = %{winner: game_state.winner, player_count: Enum.count(game_state.players)}

    changeset(%__MODULE__{}, record)
    |> Repo.insert()
  end

  def get_all() do
    Repo.all(__MODULE__)
  end
end
