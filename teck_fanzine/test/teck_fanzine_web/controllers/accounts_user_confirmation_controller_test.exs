defmodule TeckFanzineWeb.AccountsUserConfirmationControllerTest do
  use TeckFanzineWeb.ConnCase

  alias TeckFanzine.Accounts
  alias TeckFanzine.Repo
  import TeckFanzine.AccountsFixtures

  setup do
    %{accounts_user: accounts_user_fixture()}
  end

  describe "GET /accounts_users/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.accounts_user_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /accounts_users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, accounts_user: accounts_user} do
      conn =
        post(conn, Routes.accounts_user_confirmation_path(conn, :create), %{
          "accounts_user" => %{"email" => accounts_user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.AccountsUserToken, accounts_user_id: accounts_user.id).context == "confirm"
    end

    test "does not send confirmation token if Accounts user is confirmed", %{conn: conn, accounts_user: accounts_user} do
      Repo.update!(Accounts.AccountsUser.confirm_changeset(accounts_user))

      conn =
        post(conn, Routes.accounts_user_confirmation_path(conn, :create), %{
          "accounts_user" => %{"email" => accounts_user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Accounts.AccountsUserToken, accounts_user_id: accounts_user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.accounts_user_confirmation_path(conn, :create), %{
          "accounts_user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.AccountsUserToken) == []
    end
  end

  describe "GET /accounts_users/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.accounts_user_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.accounts_user_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /accounts_users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, accounts_user: accounts_user} do
      token =
        extract_accounts_user_token(fn url ->
          Accounts.deliver_accounts_user_confirmation_instructions(accounts_user, url)
        end)

      conn = post(conn, Routes.accounts_user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Accounts user confirmed successfully"
      assert Accounts.get_accounts_user!(accounts_user.id).confirmed_at
      refute get_session(conn, :accounts_user_token)
      assert Repo.all(Accounts.AccountsUserToken) == []

      # When not logged in
      conn = post(conn, Routes.accounts_user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Accounts user confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_accounts_user(accounts_user)
        |> post(Routes.accounts_user_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, accounts_user: accounts_user} do
      conn = post(conn, Routes.accounts_user_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Accounts user confirmation link is invalid or it has expired"
      refute Accounts.get_accounts_user!(accounts_user.id).confirmed_at
    end
  end
end
