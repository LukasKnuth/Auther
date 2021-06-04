defmodule AutherWeb.Authorized.TwoFactorAuthView do
  use AutherWeb, :view

  alias Auther.Security
  alias AutherWeb.Session
  alias Phoenix.HTML.Form

  def render_qrcode(conn, secret) do
    secret
    |> Security.TwoFactorAuth.otpauth_uri(Session.current_user!(conn))
    |> EQRCode.encode()
    |> EQRCode.svg()
    |> Phoenix.HTML.raw()
  end

  def tfa_input(form, field, opts \\ []) do
    opts = Keyword.merge([inputmode: "numeric", autocomplete: "one-time-code"], opts)
    Form.text_input(form, field, opts)
  end
end
