defmodule TeckFanzineWeb.AccountsUserAuthTest do
  use TeckFanzineWeb.ConnCase

  alias TeckFanzine.Accounts
  alias TeckFanzineWeb.AccountsUserAuth
  import TeckFanzine.AccountsFixtures

  @remember_me_cookie "_teck_fanzine_web_accounts_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, TeckFanzineWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{accounts_user: accounts_user_fixture(), conn: conn}
  end

  describe "log_in_accounts_user/3" do
    test "stores the accounts_user token in the session", %{conn: conn, accounts_user: accounts_user} do
      conn = AccountsUserAuth.log_in_accounts_user(conn, accounts_user)
      assert token = get_session(conn, :accounts_user_token)
      assert get_session(conn, :live_socket_id) == "accounts_users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Accounts.get_accounts_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, accounts_user: accounts_user} do
      conn = conn |> put_session(:to_be_removed, "value") |> AccountsUserAuth.log_in_accounts_user(accounts_user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, accounts_user: accounts_user} do
      conn = conn |> put_session(:accounts_user_return_to, "/hello") |> AccountsUserAuth.log_in_accounts_user(accounts_user)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, accounts_user: accounts_user} do
      conn = conn |> fetch_cookies() |> AccountsUserAuth.log_in_accounts_user(accounts_user, %{"remember_me" => "true"})
      assert get_session(conn, :accounts_user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :accounts_user_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_accounts_user/1" do
    test "erases session and cookies", %{conn: conn, accounts_user: accounts_user} do
      accounts_user_token = Accounts.generate_accounts_user_session_token(accounts_user)

      conn =
        conn
        |> put_session(:accounts_user_token, accounts_user_token)
        |> put_req_cookie(@remember_me_cookie, accounts_user_token)
        |> fetch_cookies()
        |> AccountsUserAuth.log_out_accounts_user()

      refute get_session(conn, :accounts_user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Accounts.get_accounts_user_by_session_token(accounts_user_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "accounts_users_sessions:abcdef-token"
      TeckFanzineWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> AccountsUserAuth.log_out_accounts_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if accounts_user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> AccountsUserAuth.log_out_accounts_user()
      refute get_session(conn, :accounts_user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_accounts_user/2" do
    test "authenticates accounts_user from session", %{conn: conn, accounts_user: accounts_user} do
      accounts_user_token = Accounts.generate_accounts_user_session_token(accounts_user)
      conn = conn |> put_session(:accounts_user_token, accounts_user_token) |> AccountsUserAuth.fetch_current_accounts_user([])
      assert conn.assigns.current_accounts_user.id == accounts_user.id
    end

    test "authenticates accounts_user from cookies", %{conn: conn, accounts_user: accounts_user} do
      logged_in_conn =
        conn |> fetch_cookies() |> AccountsUserAuth.log_in_accounts_user(accounts_user, %{"remember_me" => "true"})

      accounts_user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> AccountsUserAuth.fetch_current_accounts_user([])

      assert get_session(conn, :accounts_user_token) == accounts_user_token
      assert conn.assigns.current_accounts_user.id == accounts_user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, accounts_user: accounts_user} do
      _ = Accounts.generate_accounts_user_session_token(accounts_user)
      conn = AccountsUserAuth.fetch_current_accounts_user(conn, [])
      refute get_session(conn, :accounts_user_token)
      refute conn.assigns.current_accounts_user
    end
  end

  describe "redirect_if_accounts_user_is_authenticated/2" do
    test "redirects if accounts_user is authenticated", %{conn: conn, accounts_user: accounts_user} do
      conn = conn |> assign(:current_accounts_user, accounts_user) |> AccountsUserAuth.redirect_if_accounts_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if accounts_user is not authenticated", %{conn: conn} do
      conn = AccountsUserAuth.redirect_if_accounts_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_accounts_user/2" do
    test "redirects if accounts_user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> AccountsUserAuth.require_authenticated_accounts_user([])
      assert conn.halted
      assert redirected_to(conn) == Routes.accounts_user_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> AccountsUserAuth.require_authenticated_accounts_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :accounts_user_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> AccountsUserAuth.require_authenticated_accounts_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :accounts_user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> AccountsUserAuth.require_authenticated_accounts_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :accounts_user_return_to)
    end

    test "does not redirect if accounts_user is authenticated", %{conn: conn, accounts_user: accounts_user} do
      conn = conn |> assign(:current_accounts_user, accounts_user) |> AccountsUserAuth.require_authenticated_accounts_user([])
      refute conn.halted
      refute conn.status
    end
  end
end
