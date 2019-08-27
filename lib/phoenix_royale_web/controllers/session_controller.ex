defmodule PhoenixRoyaleWeb.SessionController do
  use PhoenixRoyaleWeb, :controller

  defp already_logged_in(conn, _params) do
    get_session(conn, :account_name)
    |> case do
      nil -> conn
      _account_name -> conn |> redirect(to: "/dashboard")
    end
  end

  plug :already_logged_in when action not in [:logout]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def login(conn, params) do
    conn
    |> put_session(:account_name, params["name"])
    |> redirect(to: "/")
  end

  def logout(conn, _params) do
    conn |> delete_session(:account_name) |> redirect(to: "/")
  end
end
