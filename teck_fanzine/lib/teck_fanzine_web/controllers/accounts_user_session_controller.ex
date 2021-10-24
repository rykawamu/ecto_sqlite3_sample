defmodule TeckFanzineWeb.AccountsUserSessionController do
  use TeckFanzineWeb, :controller

  alias TeckFanzine.Accounts
  alias TeckFanzineWeb.AccountsUserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"accounts_user" => accounts_user_params}) do
    %{"email" => email, "password" => password} = accounts_user_params

    if accounts_user = Accounts.get_accounts_user_by_email_and_password(email, password) do
      AccountsUserAuth.log_in_accounts_user(conn, accounts_user, accounts_user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AccountsUserAuth.log_out_accounts_user()
  end
end
