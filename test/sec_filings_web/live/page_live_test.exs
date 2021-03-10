defmodule SecFilingsWeb.PageLiveTest do
  use SecFilingsWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Companies"
    assert render(page_live) =~ "Companies"
  end
end
