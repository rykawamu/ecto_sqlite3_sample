defmodule TeckFanzineWeb.Router do
  use TeckFanzineWeb, :router

  import TeckFanzineWeb.AccountsUserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TeckFanzineWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_accounts_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TeckFanzineWeb do
    pipe_through :browser

    get "/", PageController, :index

    live "/users", UserLive.Index, :index
    live "/users/new", UserLive.Index, :new
    live "/users/:id/edit", UserLive.Index, :edit

    live "/users/:id", UserLive.Show, :show
    live "/users/:id/show/edit", UserLive.Show, :edit


  end

  # Other scopes may use custom stacks.
  # scope "/api", TeckFanzineWeb do
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
      live_dashboard "/dashboard", metrics: TeckFanzineWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", TeckFanzineWeb do
    pipe_through [:browser, :redirect_if_accounts_user_is_authenticated]

    get "/accounts_users/register", AccountsUserRegistrationController, :new
    post "/accounts_users/register", AccountsUserRegistrationController, :create
    get "/accounts_users/log_in", AccountsUserSessionController, :new
    post "/accounts_users/log_in", AccountsUserSessionController, :create
    get "/accounts_users/reset_password", AccountsUserResetPasswordController, :new
    post "/accounts_users/reset_password", AccountsUserResetPasswordController, :create
    get "/accounts_users/reset_password/:token", AccountsUserResetPasswordController, :edit
    put "/accounts_users/reset_password/:token", AccountsUserResetPasswordController, :update
  end

  scope "/", TeckFanzineWeb do
    pipe_through [:browser, :require_authenticated_accounts_user]

    get "/accounts_users/settings", AccountsUserSettingsController, :edit
    put "/accounts_users/settings", AccountsUserSettingsController, :update
    get "/accounts_users/settings/confirm_email/:token", AccountsUserSettingsController, :confirm_email
  end

  scope "/", TeckFanzineWeb do
    pipe_through [:browser]

    delete "/accounts_users/log_out", AccountsUserSessionController, :delete
    get "/accounts_users/confirm", AccountsUserConfirmationController, :new
    post "/accounts_users/confirm", AccountsUserConfirmationController, :create
    get "/accounts_users/confirm/:token", AccountsUserConfirmationController, :edit
    post "/accounts_users/confirm/:token", AccountsUserConfirmationController, :update
  end
end
