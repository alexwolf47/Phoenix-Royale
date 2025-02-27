defmodule PhoenixRoyale.Account do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias PhoenixRoyale.Repo

  schema "accounts" do
    field :name, :string
    field :unique_id, :string
    field :experience, :integer
    field :wins, :integer
    field :games_played, :integer
    field :max_distance, :integer, default: 0
    field :multiplayer_games_played, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :name,
      :unique_id,
      :experience,
      :wins,
      :games_played,
      :multiplayer_games_played,
      :max_distance
    ])
    |> validate_required([:name])
  end

  def by_id(account_id) do
    Repo.get!(__MODULE__, account_id)
  end

  def by_unique_id(unique_id) do
    query =
      from(
        a in __MODULE__,
        where: a.unique_id == ^unique_id
      )

    Repo.one(query)
  end

  def by_name(name) do
    query =
      from(
        a in __MODULE__,
        where: a.name == ^name
      )

    Repo.one(query)
  end

  def get_all() do
    Repo.all(__MODULE__)
  end

  def create(params) do
    changeset(
      %__MODULE__{
        experience: 0,
        wins: 0,
        games_played: 0,
        multiplayer_games_played: 0,
        max_distance: 0
      },
      params
    )
    |> Repo.insert()
  end

  def update(%__MODULE__{} = account, params) do
    changeset(account, params)
    |> Repo.update()
  end

  def create_unique_id(name) do
    numbers = Integer.to_string(Enum.random(10..99))
    words = word(:p) <> "-" <> word(:r)
    name <> "-" <> words <> "-" <> numbers
  end

  def order_by_account_wins() do
    from(a in PhoenixRoyale.Account,
      where: a.multiplayer_games_played != 0,
      where: a.wins != 0,
      select: %{
        name: a.name,
        wins: a.wins,
        multiplayer_games_played: a.multiplayer_games_played
      },
      order_by: [desc: a.wins, asc: a.multiplayer_games_played],
      limit: 5
    )
    |> Repo.all()
  end

  def order_by_account_distance_record() do
    from(a in PhoenixRoyale.Account,
      where: a.max_distance != 0,
      select: %{
        name: a.name,
        max_distance: a.max_distance
      },
      order_by: [desc: a.max_distance],
      limit: 5
    )
    |> Repo.all()
  end

  @p_words [
    "pace",
    "pack",
    "page",
    "paid",
    "pain",
    "pair",
    "palm",
    "park",
    "part",
    "pass",
    "past",
    "path",
    "peak",
    "pick",
    "pink",
    "pipe",
    "plan",
    "play",
    "plot",
    "plug",
    "plus",
    "poll",
    "pool",
    "poor",
    "port",
    "post",
    "pull",
    "pure",
    "push"
  ]

  @r_words [
    "race",
    "rail",
    "rain",
    "rank",
    "rare",
    "rate",
    "read",
    "real",
    "rear",
    "rely",
    "rent",
    "rest",
    "rice",
    "rich",
    "ride",
    "ring",
    "rise",
    "risk",
    "road",
    "rock",
    "role",
    "roll",
    "roof",
    "room",
    "root",
    "rose",
    "rule",
    "rush",
    "ruth"
  ]

  defp word(:p) do
    Enum.random(@p_words)
  end

  defp word(:r) do
    Enum.random(@r_words)
  end
end
