defmodule AutherWeb.Authorized.TwoFactorAuthViewTest do
  use AutherWeb.ConnCase, async: true

  import Phoenix.HTML

  alias Auther.Security.TwoFactorAuth.Mock, as: TfaMock
  alias AutherWeb.Authorized.TwoFactorAuthView, as: View

  describe "render_qrcode/2" do
    setup %{conn: conn} do
      Mox.expect(TfaMock, :otpauth_uri, fn _secret, _user ->
        "otpauth://totp/Test:some@body.com?secret=JBSWY3DPEHPK3PXP&issuer=Test"
      end)

      user = fixture(:user_with_tfa)
      conn = with_logged_in(conn, user)
      {:ok, %{conn: conn}}
    end

    test "returns safe HTML, directly renderable", %{conn: conn} do
      assert {:safe, _} = View.render_qrcode(conn, "imagine-this-was-valid")
    end

    test "returns an SVG image", %{conn: conn} do
      out = View.render_qrcode(conn, "imagine-this-was-valid")

      assert "<?xml" <> _rest = safe_to_string(out)
    end
  end

  describe "tfa_input/3" do
    test "returns a text input with expected properties" do
      out = View.tfa_input(:test, :code)

      assert safe_to_string(out) =~ "inputmode=\"numeric\""
      assert safe_to_string(out) =~ "autocomplete=\"one-time-code\""
      assert safe_to_string(out) =~ "type=\"text\""
    end

    test "correctly passes on additional params" do
      out = View.tfa_input(:test, :code, other: "value")

      assert safe_to_string(out) =~ "other=\"value\""
    end

    test "overrides directly specified parameters with own params" do
      out = View.tfa_input(:test, :code, autocomplete: "none")

      assert safe_to_string(out) =~ "autocomplete=\"one-time-code\""
    end
  end
end
