defmodule PhoenixRoyaleWeb.Router do
  use PhoenixRoyaleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug Phoenix.LiveView.Flash
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug PhoenixRoyaleWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixRoyaleWeb do
    pipe_through :browser
    get "/", SessionController, :index
    post "/", SessionController, :login
    get "/logout", SessionController, :logout
  end

  scope "/", PhoenixRoyaleWeb do
    pipe_through [:browser, :auth]

    live "/dashboard", DashboardLive, session: [:account_id]
    live "/play", RoyaleLive, session: [:account_id]
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixRoyaleWeb do
  #   pipe_through :api
  # end
end
