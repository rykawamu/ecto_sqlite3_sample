defmodule TeckFanzineWeb.AccountsUserSettingsControllerTest do
  use TeckFanzineWeb.ConnCase

  alias TeckFanzine.Accounts
  import TeckFanzine.AccountsFixtures

  setup :register_and_log_in_accounts_user

  describe "GET /accounts_users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.accounts_user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if accounts_user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.accounts_user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.accounts_user_session_path(conn, :new)
    end
  end

  describe "PUT /accounts_users/settings (change password form)" do
    test "updates the accounts_user password and resets tokens", %{conn: conn, accounts_user: accounts_user} do
      new_password_conn =
        put(conn, Routes.accounts_user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_accounts_user_password(),
          "accounts_user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.accounts_user_settings_path(conn, :edit)
      assert get_session(new_password_conn, :accounts_user_token) != get_session(conn, :accounts_user_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_accounts_user_by_email_and_password(accounts_user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.accounts_user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "accounts_user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :accounts_user_token) == get_session(conn, :accounts_user_token)
    end
  end

  describe "PUT /accounts_users/settings (change email form)" do
    @tag :capture_log
    test "updates the accounts_user email", %{conn: conn, accounts_user: accounts_user} do
      conn =
        put(conn, Routes.accounts_user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_accounts_user_password(),
          "accounts_user" => %{"email" => unique_accounts_user_email()}
        })

      assert redirected_to(conn) == Routes.accounts_user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Accounts.get_accounts_user_by_email(accounts_user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.accounts_user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "accounts_user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /accounts_users/settings/confirm_email/:token" do
    setup %{accounts_user: accounts_user} do
      email = unique_accounts_user_email()

      token =
        extract_accounts_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{accounts_user | email: email}, accounts_user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the accounts_user email once", %{conn: conn, accounts_user: accounts_user, token: token, email: email} do
      conn = get(conn, Routes.accounts_user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.accounts_user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Accounts.get_accounts_user_by_email(accounts_user.email)
      assert Accounts.get_accounts_user_by_email(email)

      conn = get(conn, Routes.accounts_user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.accounts_user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, accounts_user: accounts_user} do
      conn = get(conn, Routes.accounts_user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.accounts_user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Accounts.get_accounts_user_by_email(accounts_user.email)
    end

    test "redirects if accounts_user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.accounts_user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.accounts_user_session_path(conn, :new)
    end
  end
end
