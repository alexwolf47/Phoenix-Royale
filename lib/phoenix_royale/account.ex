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
    field :multiplayer_games_played, :integer

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :unique_id, :experience, :wins, :games_played, :multiplayer_games_played])
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
    changeset(%__MODULE__{experience: 0, wins: 0, games_played: 0, multiplayer_games_played: 0}, params)
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
