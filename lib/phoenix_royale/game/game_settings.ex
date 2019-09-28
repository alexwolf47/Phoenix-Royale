defmodule PhoenixRoyale.GameSettings do
  @doc """
  Defines the tick rate and calculates the tick rate of the game server
  """
  def tick_rate(), do: 33
  def tick_interval(), do: (1000 / tick_rate()) |> trunc()

  def server_update_interval(), do: 1500

  def postgame_screen_timeout(), do: 20 * 1000
end
