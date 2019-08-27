defmodule PhoenixRoyaleWeb.Auth do
  import Plug.Conn

  def init(_opts) do
  end

  def call(conn, _opts) do
    conn
    |> get_session(:account_name)
    |> IO.inspect(label: "get session ret")
    |> case do
      nil ->
        conn
        |> Phoenix.Controller.redirect(
          to: PhoenixRoyaleWeb.Router.Helpers.session_path(conn, :index)
        )
        |> halt()

      _account_name ->
        conn
    end
  end
end
