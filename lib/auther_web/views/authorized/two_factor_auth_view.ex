defmodule AutherWeb.Authorized.TwoFactorAuthView do
  use AutherWeb, :view

  alias Auther.Security
  alias AutherWeb.Session

  def render_qrcode(conn, secret) do
    secret
    |> Security.TwoFactorAuth.otpauth_uri(Session.current_user!(conn))
    |> EQRCode.encode()
    |> EQRCode.svg()
    |> Phoenix.HTML.raw()
  end
end
