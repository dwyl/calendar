defmodule CalWeb.AppController do
  use CalWeb, :controller

  def app(conn, _params) do

    conn = case get_flash(conn, :token) do
      nil -> conn
      token -> assign(conn, :token, token)
    end

    render(conn, :app, layout: false)
  end
end
