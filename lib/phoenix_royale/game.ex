defmodule PhoenixRoyale.Game do
  def tick(state) do
    players_list = Map.to_list(state.players)

    updated_players =
      Map.new(
        Enum.map(players_list, fn player ->
          {player_number, player_state} = player
          old_y = player_state.y
          old_x = player_state.x

          old_y_acc = player_state.y_acc

          new_player_state = %{
            player_state
            | y: old_y + old_y_acc * 0.03,
              y_acc: old_y_acc - 4,
              x: player_state.x + 1
          }

          {player_number, new_player_state}
        end)
      )

    %{state | players: updated_players}
  end
end
