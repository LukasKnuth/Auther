defmodule AutherWeb.Authorized.TwoFactorAuthController do
  use AutherWeb, :controller

  require Logger

  alias Auther.Accounts
  alias Auther.Security.TwoFactorAuth
  alias AutherWeb.Session
  alias AutherWeb.RedirectTarget
  alias Plug.Conn

  @session_key "_auther_2fa_secret"

  def show(conn, _params) do
    tfa_enabled = Accounts.has_2fa?(Session.current_user!(conn))

    conn =
      unless tfa_enabled do
        secret = TwoFactorAuth.generate_secret()

        conn
        |> put_secret(secret)
        |> Conn.assign(:secret, secret)
      else
        conn
      end

    render(conn, :show,
      action: Routes.two_factor_auth_path(conn, :update),
      tfa_enabled: tfa_enabled
    )
  end

  # todo add explicit behaviours for when 2FA is expected to be enabled/disabled but isn't

  def update(conn, %{"action" => "enable", "confirmation" => confirmation}) do
    {conn, secret} = pop_secret(conn)

    conn
    |> Session.current_user!()
    |> Accounts.enable_2fa(secret, confirmation)
    |> case do
      {:ok, _user, fallbacks} ->
        conn
        |> put_flash(:info, gettext("Two Factor Auth enabled successfully!"))
        |> render(:fallbacks,
          fallbacks: fallbacks,
          action: Routes.two_factor_auth_path(conn, :show)
        )

      {:error, {:otp, :invalid}} ->
        conn
        |> put_flash(
          :error,
          gettext("Secret and OTP token didn't match. Generated new secret, try again.")
        )
        |> redirect(to: Routes.two_factor_auth_path(conn, :show))
    end
  end

  def update(conn, %{"action" => "disable"}) do
    # todo any security query here?
    conn
    |> Session.current_user!()
    |> Accounts.disable_2fa()
    |> case do
      {:ok, _user} ->
        conn
        |> put_flash(:warn, gettext("Two Factor Auth was disabled."))
        |> redirect(to: Routes.two_factor_auth_path(conn, :show))

      {:error, changeset} ->
        Logger.error(
          "Couldn't deactivate 2FA because of invalid changeset. changeset=#{inspect(changeset)}"
        )

        conn
        |> put_flash(
          :error,
          gettext(
            "Couldn't disable Two Factor Auth because of internal problems. Try again later..."
          )
        )
        |> redirect(to: Routes.two_factor_auth_path(conn, :show))
    end
  end

  def prompt(conn, _params) do
    if Accounts.has_2fa?(Session.current_user!(conn)) do
      do_render_prompt(conn)
    else
      redirect(conn, to: RedirectTarget.get(conn))
    end
  end

  def verify(conn, params) do
    otp = get_in(params, ["two_factor_auth", "otp"])

    conn
    |> Session.current_user!()
    |> Accounts.verify_2fa(otp)
    |> case do
      :invalid ->
        do_render_prompt(
          conn,
          gettext(
            "One-time password wasn't valid. Make sure the system clock on your device is up-to-date."
          )
        )

      :valid ->
        conn
        |> AutherWeb.TwoFactorAuthPlug.two_factor_auth_completed()
        |> redirect(to: RedirectTarget.get(conn))

      {:valid, {:fallback, fallback}} ->
        conn
        |> put_flash(:info, gettext("Last Fallback key used. New ones have been generated."))
        |> render(:fallbacks, fallbacks: fallback, action: RedirectTarget.get(conn))
    end
  end

  defp do_render_prompt(conn, error \\ nil) do
    params = RedirectTarget.query_to_url_param(conn)

    render(conn, :prompt, action: Routes.two_factor_auth_path(conn, :verify, params), error: error)
  end

  defp put_secret(conn, secret), do: Conn.put_session(conn, @session_key, secret)

  @spec pop_secret(Conn.t()) :: {Conn.t(), String.t()}
  defp pop_secret(conn) do
    secret = Conn.get_session(conn, @session_key)
    conn = Conn.delete_session(conn, @session_key)
    {conn, secret}
  end
end
