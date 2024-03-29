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

    test "setting intrussiveness to :required still prompts after fresh login", %{conn: conn} do
      conn = conn
        |> with_logged_in(fixture(:user_with_tfa, intrusiveness: :required))
        |> run_plug()

      assert conn.halted
      assert redirected_to(conn) == tfa_prompt_with_target(conn)
    end

    test "redirects to TFA prompt and includes original route as target" do
      conn =
        :get
        |> build_conn("/some/where", hello: "world")
        |> with_logged_in(fixture(:user_with_tfa))
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

    test "always redirects to TFA prompt if Plug is initialized with force-option", %{
      conn_tfa: conn
    } do
      conn =
        conn
        |> with_tfa_completed()
        |> run_plug(force: true)

      assert conn.halted
      assert redirected_to(conn) == tfa_prompt_with_target(conn)
    end

    test "continues after prompt when Plug is instantiated with force-option", %{conn_tfa: conn} do
      # This is to verify that forcing 2FA prompt doesn't do so again on the actual request following the prompt.
      user = Session.current_user!(conn)

      conn = run_plug(conn, force: true)
      assert conn.halted
      assert redirected_to(conn) == tfa_prompt_with_target(conn)

      retained_session = Plug.Conn.get_session(conn)
      conn =
        conn
        |> recycle()
        |> with_logged_in(user)
        # todo workaround to restore the session. init_test_session/2 (called in with_logged_in/2) clears session state!
        |> init_test_session(retained_session)
        |> run_plug(force: true)
      refute conn.halted
    end

    test "setting intrussiveness to :required doesn't re-prompt after time", %{conn: conn} do
      conn = conn
        |> with_logged_in(fixture(:user_with_tfa, intrusiveness: :required))
        |> with_tfa_completed(0)
        |> run_plug()

      refute conn.halted
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

  defp run_plug(conn, options \\ []) do
    TwoFactorAuthPlug.call(conn, TwoFactorAuthPlug.init(options))
  end

  defp tfa_prompt_with_target(conn) do
    Routes.two_factor_auth_path(conn, :prompt, RedirectTarget.as_url_param!("/"))
  end
end
