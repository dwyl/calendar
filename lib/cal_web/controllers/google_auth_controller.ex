defmodule CalWeb.GoogleAuthController do
  use CalWeb, :controller

  @doc """
  `index/2` handles the callback from Google Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)
    # {:ok, profile} = ElixirAuthGoogle.get_user_profile(token.access_token)
    dbg(token)

    conn
    # |> put_flash(:person_email, profile.email)
    |> put_flash(:token, token)
    |> redirect(to: ~p"/app")
  end
end
