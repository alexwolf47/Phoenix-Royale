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

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixRoyaleWeb do
    pipe_through :browser

    get "/", PageController, :index
    live "/clock", ClockLive

    live "/play", RoyaleLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixRoyaleWeb do
  #   pipe_through :api
  # end
end
