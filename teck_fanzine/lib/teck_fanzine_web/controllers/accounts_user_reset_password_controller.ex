defmodule TeckFanzineWeb.AccountsUserResetPasswordController do
  use TeckFanzineWeb, :controller

  alias TeckFanzine.Accounts

  plug :get_accounts_user_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"accounts_user" => %{"email" => email}}) do
    if accounts_user = Accounts.get_accounts_user_by_email(email) do
      Accounts.deliver_accounts_user_reset_password_instructions(
        accounts_user,
        &Routes.accounts_user_reset_password_url(conn, :edit, &1)
      )
    end

    # In order to prevent user enumeration attacks, regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Accounts.change_accounts_user_password(conn.assigns.accounts_user))
  end

  # Do not log in the accounts_user after reset password to avoid a
  # leaked token giving the accounts_user access to the account.
  def update(conn, %{"accounts_user" => accounts_user_params}) do
    case Accounts.reset_accounts_user_password(conn.assigns.accounts_user, accounts_user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.accounts_user_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_accounts_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if accounts_user = Accounts.get_accounts_user_by_reset_password_token(token) do
      conn |> assign(:accounts_user, accounts_user) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
