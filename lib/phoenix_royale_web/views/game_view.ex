defmodule PhoenixRoyaleWeb.GameView do
  use PhoenixRoyaleWeb, :view
  require Integer

  def get_player_y(player_id, game_state) do
    Map.get(game_state.players, player_id).y
  end

  def get_player_x(player_id, game_state) do
    Map.get(game_state.players, player_id).x
  end

  def death_type(death_type) do
    case death_type do
      :comet -> "a comet."
      :collision -> "flying into something hard."
      :storm -> "the JavaStorm."
    end
  end
end
