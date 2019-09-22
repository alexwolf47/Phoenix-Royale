defmodule PhoenixRoyaleWeb.SessionController do
  use PhoenixRoyaleWeb, :controller
  alias PhoenixRoyale.Account

  defp already_logged_in(conn, _params) do
    get_session(conn, :account_id)
    |> case do
      nil -> conn
      _account_id -> conn |> redirect(to: "/dashboard")
    end
  end

  plug :already_logged_in when action not in [:logout]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def login(conn, params) do
    unique_id = Account.create_unique_id(params["name"])

    Account.create(Map.put(params, "unique_id", unique_id))
    |> redirect_new_account(conn, params)
  end

  defp redirect_new_account({:error, _err}, conn, _params) do
    conn
    |> put_flash(:info, "Unable to create account")
    |> redirect(to: "/")
  end

  defp redirect_new_account({:ok, account}, conn, _params) do
    conn
    |> put_session(:account_id, account.id)
    |> redirect(to: "/")
  end

  def logout(conn, _params) do
    conn |> delete_session(:account_id) |> redirect(to: "/")
  end
end
