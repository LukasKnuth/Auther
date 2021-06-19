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
    opts = Keyword.merge(opts, inputmode: "numeric", autocomplete: "one-time-code")
    Form.text_input(form, field, opts)
  end

  def render_fallbacks(fallbacks) do
    fallbacks
    |> Enum.chunk_every(5)
    |> Enum.map(&Enum.join(&1, " | "))
    |> Enum.join("\n")
  end
end
