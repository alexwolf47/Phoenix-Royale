defmodule PhoenixRoyale.GameRecord do
  use Ecto.Schema
  alias PhoenixRoyale.Repo
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

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
    record = %{winner: game_state.winner, player_count: game_state.player_count}

    changeset(%__MODULE__{}, record)
    |> Repo.insert()
  end

  def get_all() do
    Repo.all(__MODULE__)
  end

  def order_by_account_wins() do
    from(gr in PhoenixRoyale.GameRecord,
      where: gr.player_count != 1,
      select: %{winner: gr.winner, wins: count(gr)},
      group_by: gr.winner,
      order_by: [desc: count(gr)]
    )
    |> Repo.all()
  end
end
