defmodule PhoenixRoyaleWeb.PageController do
  use PhoenixRoyaleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
