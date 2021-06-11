defmodule AutherWeb.TwoFactorAuthPlugTest do
  use AutherWeb.ConnCase

  alias AutherWeb.RedirectTarget
  alias AutherWeb.Session
  alias AutherWeb.TwoFactorAuthPlug

  setup %{conn: conn} do
    conn_logged_in = with_logged_in(conn, fixture(:user))
    conn_tfa = with_logged_in(conn, fixture(:user_with_tfa))
    {:ok, %{conn_logged_in: conn_logged_in, conn_tfa: conn_tfa}}
  end

  describe "call/2" do
    test "redirects to TFA prompt if user is freshly logged in", %{conn_tfa: conn} do
      conn = run_plug(conn)

      assert conn.halted
      assert redirected_to(conn) == tfa_prompt_with_target(conn)
    end

    test "redirects to TFA prompt and includes original route as target", %{conn_tfa: conn} do
      conn =
        :get
        |> build_conn("/some/where", hello: "world")
        |> with_logged_in(Session.current_user!(conn))
        |> run_plug()

      params = RedirectTarget.as_url_param!("/some/where?hello=world")

      assert conn.halted
      assert redirected_to(conn) == Routes.two_factor_auth_path(conn, :prompt, params)
    end

    test "redirects to TFA prompt if user wasn't prompted in a while", %{conn_tfa: conn} do
      conn =
        conn
        |> with_tfa_completed(0)
        |> run_plug()

      assert conn.halted
      assert redirected_to(conn) == tfa_prompt_with_target(conn)
    end

    test "continues if user was prompted recently", %{conn_tfa: conn} do
      conn =
        conn
        |> with_tfa_completed()
        |> run_plug()

      refute conn.halted
    end

    test "does nothing if user doesn't have TFA enabled", %{conn_logged_in: conn} do
      conn_after = run_plug(conn)

      refute conn_after.halted
      assert conn_after == conn
    end
  end

  describe "two_factor_auth_completed/1" do
    test "doesn't prompt on next request", %{conn_tfa: conn} do
      conn_verify = run_plug(conn)

      assert conn_verify.halted
      assert redirected_to(conn_verify) == tfa_prompt_with_target(conn)

      conn_after =
        conn
        |> TwoFactorAuthPlug.two_factor_auth_completed()
        |> run_plug()

      refute conn_after.halted
    end
  end

  defp run_plug(conn) do
    TwoFactorAuthPlug.call(conn, TwoFactorAuthPlug.init([]))
  end

  defp tfa_prompt_with_target(conn) do
    Routes.two_factor_auth_path(conn, :prompt, RedirectTarget.as_url_param!("/"))
  end
end
