defmodule AutherWeb.Authorized.TwoFactorAuthControllerTest do
  use AutherWeb.ConnCase

  alias Auther.Accounts
  alias Auther.Accounts.{User, TwoFactorAuth}
  alias Auther.Security.TwoFactorAuth.Mock, as: TfaMock
  alias AutherWeb.RedirectTarget
  alias AutherWeb.Session

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn_user = with_logged_in(conn, fixture(:user))

    conn_tfa =
      conn
      |> with_logged_in(fixture(:user_with_tfa))
      |> with_tfa_completed()

    {:ok, %{conn_tfa: conn_tfa, conn_user: conn_user}}
  end

  describe "GET #show" do
    test_auth_required(get: two_factor_auth_path(:show))

    test "shows 'disabled' and enable form if user has no TFA setup", %{conn_user: conn} do
      TfaMock
      |> expect(:generate_secret, fn -> "something" end)
      |> expect(:otpauth_uri, fn _, _ ->
        "otpauth://totp/Test:some@body.com?secret=JBSWY3DPEHPK3PXP&issuer=Test"
      end)

      conn = get(conn, Routes.two_factor_auth_path(conn, :show))

      html_response(conn, 200)
      |> assert_html("strong", text: "Disabled")
      |> assert_html("button[name=action][value=enable]")
    end

    test "shows 'enabled' and disable button if user has no TFA setup", %{conn_tfa: conn} do
      expect(TfaMock, :otpauth_uri, 0, fn _, _ -> "unimportant" end)

      conn = get(conn, Routes.two_factor_auth_path(conn, :show))

      html_response(conn, 200)
      |> assert_html("strong", text: "Enabled")
      |> assert_html("button[name=action][value=disable]")
    end
  end

  test_auth_required(post: two_factor_auth_path(:update))

  describe "POST #update (2FA disabled)" do
    test "enables TFA, flashes and redirects if given 2FA key is valid", %{conn_user: conn} do
      expect(TfaMock, :validate, fn _, _, _ -> {:valid, :otp} end)

      secret = "some-secret-here"
      conn = Plug.Conn.put_session(conn, "_auther_2fa_secret", secret)
      user = Session.current_user!(conn)

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :update), %{
          "action" => "enable",
          "confirmation" => "irrelevant"
        })

      assert redirected_to(conn) == Routes.two_factor_auth_path(conn, :show)
      assert get_flash(conn, :info) =~ "enabled successfully"
      assert %User{two_factor_auth: %TwoFactorAuth{secret: ^secret}} = Accounts.get_user!(user.id)
    end

    test "flashes and redirects if given 2FA key is invalid", %{conn_user: conn} do
      expect(TfaMock, :validate, fn _, _, _ -> :invalid end)

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :update), %{
          "action" => "enable",
          "confirmation" => "irrelevant"
        })

      assert redirected_to(conn) == Routes.two_factor_auth_path(conn, :show)
      assert get_flash(conn, :error) =~ "Secret and OTP token didn't match"
    end
  end

  describe "POST #update (2FA enabled)" do
    test "disabled TFA, flahses and redirects", %{conn_tfa: conn} do
      user = Session.current_user!(conn)

      conn = post(conn, Routes.two_factor_auth_path(conn, :update), %{"action" => "disable"})

      assert redirected_to(conn) == Routes.two_factor_auth_path(conn, :show)
      assert get_flash(conn, :warn) =~ "was disabled"
      assert %User{two_factor_auth: nil} = Accounts.get_user!(user.id)
    end
  end

  describe "GET #prompt" do
    test_auth_required(get: two_factor_auth_path(:prompt))

    test "renders form if TFA is enabled", %{conn_tfa: conn} do
      conn = get(conn, Routes.two_factor_auth_path(conn, :prompt))

      html_response(conn, 200)
      |> assert_html("h2", text: "Two-Factor Authentication")
      |> assert_html("form")
    end

    test "redirects to account-page if TFA is disabled", %{conn_user: conn} do
      conn = get(conn, Routes.two_factor_auth_path(conn, :prompt))

      assert redirected_to(conn) == Routes.account_path(conn, :show)
    end

    test "redirects to given target if TFA is disabled", %{conn_user: conn} do
      params = RedirectTarget.as_url_param!("/some/where")
      conn = get(conn, Routes.two_factor_auth_path(conn, :prompt, params))

      assert redirected_to(conn) == "/some/where"
    end
  end

  describe "POST #verify" do
    test_auth_required(post: two_factor_auth_path(:verify))

    test "redirects to account-page if TFA is valid", %{conn_tfa: conn} do
      expect(TfaMock, :validate, fn _, _, _ -> {:valid, :otp} end)

      conn = post(conn, Routes.two_factor_auth_path(conn, :verify))

      assert redirected_to(conn) == Routes.account_path(conn, :show)
    end

    test "redirects to given target if TFA is valid", %{conn_tfa: conn} do
      expect(TfaMock, :validate, fn _, _, _ -> {:valid, :otp} end)

      params = RedirectTarget.as_url_param!("/other/path")
      conn = post(conn, Routes.two_factor_auth_path(conn, :verify, params))

      assert redirected_to(conn) == "/other/path"
    end

    test "re-renders form with error if TFA is invalid", %{conn_tfa: conn} do
      expect(TfaMock, :validate, fn _, _, _ -> :invalid end)

      conn = post(conn, Routes.two_factor_auth_path(conn, :verify))

      html_response(conn, 200)
      |> assert_html("p.error")
      |> assert_html("form")
    end
  end
end
