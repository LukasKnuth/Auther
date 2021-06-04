defmodule AutherWeb.SessionController do
  use AutherWeb, :controller

  alias AutherWeb.RedirectTarget
  alias AutherWeb.Session

  def form(conn, _params) do
    if Session.is_signed_in?(conn) do
      login_redirect(conn)
    else
      do_render_form(conn)
    end
  end

  defp do_render_form(conn) do
    params = RedirectTarget.query_to_url_param(conn)
    render(conn, :form, action: Routes.session_path(conn, :login, params))
  end

  def login(conn, %{"email" => email, "password" => password}) do
    Session.authenticate_user(email, password)
    |> login_reply(conn)
  end

  def login(conn, _params), do: login_reply({:error, :unknown_combination}, conn)

  defp login_reply({:error, :unknown_combination}, conn) do
    conn
    |> put_flash(:error, gettext("Unknown email/password combination"))
    |> do_render_form()
  end

  defp login_reply({:ok, user}, conn) do
    conn
    |> Session.sign_in(user)
    |> put_flash(:info, gettext("Succesfully logged in"))
    |> login_redirect()
  end

  def logout(conn, _params) do
    conn
    |> Session.sign_out()
    |> put_flash(:info, gettext("Succesfully logged out"))
    |> redirect(to: Routes.session_path(conn, :form))
  end

  defp login_redirect(conn), do: redirect(conn, to: RedirectTarget.get(conn))
end
