defmodule TeckFanzineWeb.AccountsUserRegistrationController do
  use TeckFanzineWeb, :controller

  alias TeckFanzine.Accounts
  alias TeckFanzine.Accounts.AccountsUser
  alias TeckFanzineWeb.AccountsUserAuth

  def new(conn, _params) do
    changeset = Accounts.change_accounts_user_registration(%AccountsUser{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"accounts_user" => accounts_user_params}) do
    case Accounts.register_accounts_user(accounts_user_params) do
      {:ok, accounts_user} ->
        {:ok, _} =
          Accounts.deliver_accounts_user_confirmation_instructions(
            accounts_user,
            &Routes.accounts_user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Accounts user created successfully.")
        |> AccountsUserAuth.log_in_accounts_user(accounts_user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
