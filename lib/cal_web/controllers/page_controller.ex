defmodule CalWeb.PageController do
  use CalWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    oauth_google_url = ElixirAuthGoogle.generate_oauth_url(CalWeb.Endpoint.url())
    render(conn, :home, layout: false, oauth_google_url: oauth_google_url)
  end
end
