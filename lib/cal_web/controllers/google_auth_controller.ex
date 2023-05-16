defmodule CalWeb.GoogleAuthController do
  use CalWeb, :controller

  @doc """
  `index/2` handles the callback from Google Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)

    conn
    |> put_flash(:token, token)
    |> redirect(to: ~p"/app")
  end
end
