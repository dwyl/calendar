defmodule CalWeb.GoogleAuthControllerTest do
  use CalWeb.ConnCase

  test "google_handler/2 for google auth callback", %{conn: conn} do
    conn = get(conn, "/auth/google/callback", %{code: "234"})
    assert redirected_to(conn) =~ "/app"
  end
end
