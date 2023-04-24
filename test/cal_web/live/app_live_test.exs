defmodule CalWeb.AppLiveTest do
  use CalWeb.ConnCase
  import Phoenix.LiveViewTest

  test "normal mount", %{conn: conn} do
    conn = get(conn, "/app")
    assert html_response(conn, 200) =~ "List of events"
  end

  test "connected mount", %{conn: conn} do
    conn = add_assigns_to_conn(conn)
    {:ok, _view, html} = live(conn, "/app")

    # Should render the page and one event
    assert html =~ "List of events"
    assert html =~ "Some title"
  end

  test "no token should redirect to home", %{conn: conn} do
    view = live(conn, "/app")

    # Should redirect to home
    assert view == {:error, {:live_redirect, %{kind: :push, to: "/"}}}
  end



  defp add_assigns_to_conn(conn) do

    Map.put(conn, :assigns, %{
      flash: %{
        "token" => %{
          access_token: "access_token",
          expires_in: 3599,
          id_token: "id_token",
          scope: "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/calendar.events.readonly openid https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.settings.readonly",
          token_type: "Bearer"
        }
      },
    })
  end
end
