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
    test "enables TFA and renders fallback keys if given 2FA key is valid", %{conn_user: conn} do
      TfaMock
      |> expect(:validate, fn "980421", _, _ -> {:valid, :otp} end)
      |> expect(:generate_fallback, 3, fn -> "NOTA-FBKY" end)
      |> expect(:hash_fallback, 3, fn "NOTA-FBKY" -> "dis-be-a-hash" end)

      secret = "some-secret-here"
      conn = Plug.Conn.put_session(conn, "_auther_2fa_secret", secret)
      user = Session.current_user!(conn)

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :update), %{
          "action" => "enable",
          "confirmation" => "980421"
        })

      link = Routes.two_factor_auth_path(conn, :show)

      response(conn, 200)
      |> assert_html("pre code", match: "NOTA-FBKY")
      |> assert_html("a[href='#{link}']", count: 1)

      assert get_flash(conn, :info) =~ "enabled successfully"
      assert %User{two_factor_auth: %TwoFactorAuth{secret: ^secret}} = Accounts.get_user!(user.id)
    end

    test "flashes and redirects if given 2FA key is invalid", %{conn_user: conn} do
      expect(TfaMock, :validate, fn "759012", _, _ -> :invalid end)

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :update), %{
          "action" => "enable",
          "confirmation" => "759012"
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
      expect(TfaMock, :validate, fn "748902", _, _ -> {:valid, :otp} end)

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :verify), %{
          two_factor_auth: %{otp: "748902"}
        })

      assert redirected_to(conn) == Routes.account_path(conn, :show)
    end

    test "redirects to given target if TFA is valid", %{conn_tfa: conn} do
      expect(TfaMock, :validate, fn "874912", _, _ -> {:valid, :otp} end)

      params = RedirectTarget.as_url_param!("/other/path")

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :verify, params), %{
          two_factor_auth: %{otp: "874912"}
        })

      assert redirected_to(conn) == "/other/path"
    end

    test "redirects to given target if valid fallback code is given", %{conn_tfa: conn} do
      fallbacks = ["imagine-this-hashed", "another-hashed-fallback"]
      expect(TfaMock, :validate, fn "FBA1-C0D3", _, _ -> {:valid, {:fallback, fallbacks}} end)

      params = RedirectTarget.as_url_param!("/nother/route")

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :verify, params), %{
          two_factor_auth: %{otp: "FBA1-C0D3"}
        })

      assert redirected_to(conn) == "/nother/route"
    end

    test "renders new fallback codes and button to target if last fallback is given", %{
      conn_tfa: conn
    } do
      TfaMock
      |> expect(:validate, fn "FALL-BACK", _, _ -> {:valid, {:fallback, []}} end)
      |> expect(:generate_fallback, 3, fn -> "NEWF-BKY1" end)
      |> expect(:hash_fallback, 3, fn "NEWF-BKY1" -> "hashy-mc-hashl" end)

      params = RedirectTarget.as_url_param!("/other/path")

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :verify, params), %{
          two_factor_auth: %{otp: "FALL-BACK"}
        })

      html_response(conn, 200)
      |> assert_html("pre code", match: "NEWF-BKY1")
      |> assert_html("a[href='/other/path']", count: 1)
    end

    test "re-renders form with error if TFA is invalid", %{conn_tfa: conn} do
      expect(TfaMock, :validate, fn "invalid", _, _ -> :invalid end)

      conn =
        post(conn, Routes.two_factor_auth_path(conn, :verify), %{
          two_factor_auth: %{otp: "invalid"}
        })

      html_response(conn, 200)
      |> assert_html("p.error")
      |> assert_html("form")
    end
  end
end
