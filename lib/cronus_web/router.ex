defmodule CronusWeb.Router do
  use CronusWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CronusWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CronusWeb do
    pipe_through :browser

    live "/dashboard", DashboardLive
    get "/", PageController, :home
  end

  scope "/api", CronusWeb do
    pipe_through :api
  end

  if Application.compile_env(:cronus, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CronusWeb.Telemetry
    end
  end
end
