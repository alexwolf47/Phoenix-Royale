defmodule PhoenixRoyale.GameServer do
  use GenServer
  alias PhoenixRoyale.Game

  @server_name {:global, Server}

  defmodule GameState do
    defstruct server_status: :need_players,
              player_count: 0,
              players: %{}
  end

  defmodule Player do
    defstruct name: "",
              pid: nil,
              y: 50,
              y_acc: 0,
              x: 0
  end

  def start_link(_init_args) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, %GameState{}, name: @server_name)
  end

  def init(server) do
    :timer.send_interval(33, self(), :tick)
    {:ok, server}
  end

  @doc "allows the status of the server to be queried - client interface"

  def state() do
    GenServer.call(@server_name, :state)
  end

  @doc "allows a player to join the server - client interface"

  def join(name) do
    GenServer.call(@server_name, {:join, name})
  end

  def jump(player_number) do
    GenServer.cast(@server_name, {:jump, player_number})
  end

  def handle_info(:tick, state) do
    if state.server_status == :full do
      new_state = Game.tick(state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @doc "handles the call and returns the status of the server"
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  ### functions for players joining the server ###

  # for first player attempting to join

  def handle_call({:join, name}, {pid, _ref} = _from, state) do
    player = %Player{name: name, pid: pid}
    number_of_players = Map.size(state.players)
    players = Map.put(state.players, number_of_players + 1, player)

    # status =
    #   if number_of_players > 0 do
    #     :full
    #   else
    #     :need_players
    #   end

    new_state = %{
      state
      | player_count: state.player_count + 1,
        players: players,
        server_status: :full
    }

    {:reply, @successful_join_message, new_state}
  end

  def handle_cast({:jump, player_number}, state) do
    player = Map.get(state.players, player_number)

    updated_player = %{player | y_acc: player.y_acc + 100}
    updated_players = Map.put(state.players, player_number, updated_player)
    new_state = %{state | players: updated_players}
    {:noreply, new_state}
  end
end
