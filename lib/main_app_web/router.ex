defmodule MainAppWeb.Router do
  use MainAppWeb, :router

  import MainAppWeb.UserAuth
  import MainAppWeb.Application

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MainAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug :assign_application_to_scope
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MainAppWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", MainAppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:main_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MainAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MainAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {MainAppWeb.UserAuth, :require_authenticated},
        {MainAppWeb.Application, :mount_current_scope}
      ] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/applications", ApplicationLive.Index, :index
      live "/applications/new", ApplicationLive.Form, :new
      live "/applications/:id", ApplicationLive.Show, :show
      live "/applications/:id/edit", ApplicationLive.Form, :edit
    end

    post "/users/set-application", ApplicationSessionController, :set_application

    post "/users/update-password", UserSessionController, :update_password

    live_session :require_authenticated_user_and_application,
      on_mount: [
        {MainAppWeb.UserAuth, :require_authenticated},
        {MainAppWeb.Application, :require_application}
      ] do
      live "/products", ApplicationLive.Index, :index
    end
  end

  scope "/", MainAppWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{MainAppWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
