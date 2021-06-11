defmodule AutherWeb.Router do
  use AutherWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug AutherWeb.AuthPlug
  end

  pipeline :two_factor_auth do
    plug AutherWeb.TwoFactorAuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AutherWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/session", AutherWeb do
    pipe_through :browser

    get "/new", SessionController, :form
    post "/login", SessionController, :login
    get "/logout", SessionController, :logout
  end

  scope "/account", AutherWeb.Authorized do
    pipe_through [:browser, :auth]

    get "/2fa/prompt", TwoFactorAuthController, :prompt
    post "/2fa/prompt", TwoFactorAuthController, :verify
  end

  scope "/account", AutherWeb.Authorized do
    pipe_through [:browser, :auth, :two_factor_auth]

    resources "/", AccountController, only: [:show, :edit, :update], singleton: true

    get "/2fa", TwoFactorAuthController, :show
    post "/2fa/update", TwoFactorAuthController, :update
  end

  # Other scopes may use custom stacks.
  # scope "/api", AutherWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: AutherWeb.Telemetry
    end
  end
end
