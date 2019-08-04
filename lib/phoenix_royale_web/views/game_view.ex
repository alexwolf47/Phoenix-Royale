defmodule PhoenixRoyaleWeb.GameView do
  use PhoenixRoyaleWeb, :view

  def get_player_y(player_id, game_state) do
    Map.get(game_state.players, player_id).y
  end

end