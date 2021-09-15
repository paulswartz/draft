defmodule DraftWeb.Router do
  use DraftWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug(DraftWeb.AuthManager.Pipeline)
  end

  pipeline :ensure_auth do
    plug(Guardian.Plug.EnsureAuthenticated)
  end

  pipeline :ensure_admin do
    plug(DraftWeb.AuthManager.EnsureAdminGroup)
  end

  pipeline :redirect_http do
    if Application.get_env(:draft, :redirect_http?) do
      plug(Plug.SSL, rewrite_on: [:x_forwarded_proto])
    end
  end

  scope "/", DraftWeb do
    get "/_health", HealthController, :index
  end

  scope "/", DraftWeb do
    pipe_through [:redirect_http, :browser, :auth, :ensure_auth]
    get "/", PageController, :index
  end

  scope "/auth", DraftWeb do
    pipe_through([:browser])
    get("/:provider", AuthController, :request)
    get("/:provider/callback", AuthController, :callback)
  end

  scope "/admin", DraftWeb do
    pipe_through [:redirect_http, :browser, :auth, :ensure_auth, :ensure_admin]

    get "/", AdminController, :index
  end

  scope "/admin/spoof", DraftWeb do
    pipe_through [:redirect_http, :browser, :auth, :ensure_auth, :ensure_admin]

    get "/", SpoofUserController, :index
    post "/", SpoofUserController, :create
    get "/operator", SpoofUserController, :show
  end

  scope "/api", DraftWeb.API do
    pipe_through [:redirect_http, :browser, :auth, :ensure_auth, :api]

    get "/vacation_availability", VacationAvailabilityController, :index

    resources "/vacation/preferences", VacationPreferenceController,
      only: [:create, :update],
      param: "previous_preference_set_id"

    get "/vacation/preferences/latest", VacationPreferenceController, :show_latest

    get "/vacation/pick_overview", EmployeeVacationPickController, :show
  end

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
      live_dashboard "/dashboard", metrics: DraftWeb.Telemetry
    end
  end
end
