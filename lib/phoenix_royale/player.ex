defmodule PhoenixRoyale.Player do
  defstruct name: "",
            started: false,
            alive: true,
            pid: nil,
            y: 50,
            y_acc: 0,
            x: 0,
            x_speed: 10
end
