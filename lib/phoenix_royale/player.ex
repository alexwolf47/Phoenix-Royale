defmodule PhoenixRoyale.Player do
  defstruct name: "",
            uuid: nil,
            alive: true,
            pid: nil,
            y: 50,
            y_speed: 0,
            x: 0,
            x_speed: 10,
            position: nil
end
