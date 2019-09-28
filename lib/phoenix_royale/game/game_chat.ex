defmodule PhoenixRoyale.GameChat do
  use GenServer

  @server_name {:global, __MODULE__}

  def start_link(_init_args) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, %{messages: []}, name: @server_name)
  end

  def init(server) do
    {:ok, server}
  end

  def state() do
    GenServer.call(@server_name, :state)
  end

  def new_message(author, content) do
    GenServer.cast(@server_name, {:new_message, author, content})
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:new_message, author, content}, state) do
    message = {author, content}
    {:noreply, %{state | messages: [message | state.messages]}}
  end
end
