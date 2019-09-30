defmodule PhoenixRoyale.Player do
  defstruct name: "",
            unique_id: "",
            uuid: nil,
            alive: true,
            death_type: nil,
            storm_at_death: nil,
            pid: nil,
            y: 50,
            y_speed: 0,
            x: 0,
            x_speed: 400 / PhoenixRoyale.GameSettings.tick_rate(),
            pipe: 0,
            position: nil
end
