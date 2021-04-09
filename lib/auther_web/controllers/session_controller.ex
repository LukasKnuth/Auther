defmodule AutherWeb.SessionController do
  use AutherWeb, :controller
  import AutherWeb.Gettext

  alias AutherWeb.Session

  def form(conn, _params) do
    if Session.is_signed_in?(conn) do
      login_redirect(conn)
    else
      render(conn, :form)
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    Session.authenticate_user(email, password)
    |> login_reply(conn)
  end

  def login(conn, _params), do: login_reply({:error, :unknown_combination}, conn)

  defp login_reply({:error, :unknown_combination}, conn) do
    conn
    |> put_flash(:error, gettext("Unknown email/password combination"))
    |> render(:form)
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

  # todo later: restore sent redirect_url, redirect there!
  defp login_redirect(conn), do: redirect(conn, to: Routes.account_path(conn, :show))
end
