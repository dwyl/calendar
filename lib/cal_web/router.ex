defmodule CalWeb.Router do
  use CalWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CalWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # pipeline :api do
  #   plug :accepts, ["json"]
  # end

  scope "/", CalWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/app", AppLive

    get "/auth/google/callback", GoogleAuthController, :index
  end
end
