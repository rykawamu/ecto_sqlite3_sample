defmodule TeckFanzineWeb.AccountsUserSettingsController do
  use TeckFanzineWeb, :controller

  alias TeckFanzine.Accounts
  alias TeckFanzineWeb.AccountsUserAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "accounts_user" => accounts_user_params} = params
    accounts_user = conn.assigns.current_accounts_user

    case Accounts.apply_accounts_user_email(accounts_user, password, accounts_user_params) do
      {:ok, applied_accounts_user} ->
        Accounts.deliver_update_email_instructions(
          applied_accounts_user,
          accounts_user.email,
          &Routes.accounts_user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.accounts_user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "accounts_user" => accounts_user_params} = params
    accounts_user = conn.assigns.current_accounts_user

    case Accounts.update_accounts_user_password(accounts_user, password, accounts_user_params) do
      {:ok, accounts_user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:accounts_user_return_to, Routes.accounts_user_settings_path(conn, :edit))
        |> AccountsUserAuth.log_in_accounts_user(accounts_user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_accounts_user_email(conn.assigns.current_accounts_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.accounts_user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.accounts_user_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    accounts_user = conn.assigns.current_accounts_user

    conn
    |> assign(:email_changeset, Accounts.change_accounts_user_email(accounts_user))
    |> assign(:password_changeset, Accounts.change_accounts_user_password(accounts_user))
  end
end
