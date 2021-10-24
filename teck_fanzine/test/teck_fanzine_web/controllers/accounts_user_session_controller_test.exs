defmodule TeckFanzineWeb.AccountsUserSessionControllerTest do
  use TeckFanzineWeb.ConnCase

  import TeckFanzine.AccountsFixtures

  setup do
    %{accounts_user: accounts_user_fixture()}
  end

  describe "GET /accounts_users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.accounts_user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"
    end

    test "redirects if already logged in", %{conn: conn, accounts_user: accounts_user} do
      conn = conn |> log_in_accounts_user(accounts_user) |> get(Routes.accounts_user_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /accounts_users/log_in" do
    test "logs the accounts_user in", %{conn: conn, accounts_user: accounts_user} do
      conn =
        post(conn, Routes.accounts_user_session_path(conn, :create), %{
          "accounts_user" => %{"email" => accounts_user.email, "password" => valid_accounts_user_password()}
        })

      assert get_session(conn, :accounts_user_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ accounts_user.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the accounts_user in with remember me", %{conn: conn, accounts_user: accounts_user} do
      conn =
        post(conn, Routes.accounts_user_session_path(conn, :create), %{
          "accounts_user" => %{
            "email" => accounts_user.email,
            "password" => valid_accounts_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_teck_fanzine_web_accounts_user_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the accounts_user in with return to", %{conn: conn, accounts_user: accounts_user} do
      conn =
        conn
        |> init_test_session(accounts_user_return_to: "/foo/bar")
        |> post(Routes.accounts_user_session_path(conn, :create), %{
          "accounts_user" => %{
            "email" => accounts_user.email,
            "password" => valid_accounts_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, accounts_user: accounts_user} do
      conn =
        post(conn, Routes.accounts_user_session_path(conn, :create), %{
          "accounts_user" => %{"email" => accounts_user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /accounts_users/log_out" do
    test "logs the accounts_user out", %{conn: conn, accounts_user: accounts_user} do
      conn = conn |> log_in_accounts_user(accounts_user) |> delete(Routes.accounts_user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :accounts_user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the accounts_user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.accounts_user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :accounts_user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
