defmodule PhoenixRoyaleWeb.PageControllerTest do
  use PhoenixRoyaleWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "My Phrenzy Entry"
  end
end
