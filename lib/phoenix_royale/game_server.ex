defmodule PhoenixRoyale.GameServer do
  use GenServer

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
              y_acc: 0
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

    # IO.inspect(state, label: "players befopre")
    players_list = Map.to_list(state.players)


    updated_players = Map.new(Enum.map(players_list, fn player -> {player_number, player_state} = player
    old_y = player_state.y
    old_y_acc = player_state.y_acc
    new_player_state = %{ player_state | y: old_y + (old_y_acc * 0.01), y_acc: old_y_acc - 5}
    {player_number, new_player_state}
    end))


    new_state = %{ state | players: updated_players}

    # IO.inspect(new_state, label: "players afters")

    {:noreply, new_state}

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


    new_state = %{state | player_count: state.player_count + 1, players: players, server_status: :full}
    {:reply, @successful_join_message, new_state}
  end

  def handle_cast({:jump, player_number}, state) do

    player = Map.get(state.players, player_number)
    updated_player = %{ player | y_acc: player.y_acc + 80}
    updated_players = Map.put(state.players, player_number, updated_player)
    new_state = %{state | players: updated_players}
    {:noreply, new_state}
  end
end
