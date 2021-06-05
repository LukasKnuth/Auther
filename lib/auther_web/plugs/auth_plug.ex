defmodule AutherWeb.AuthPlug do
  alias AutherWeb.Router.Helpers, as: Routes
  alias AutherWeb.RedirectTarget
  alias AutherWeb.Session
  alias Plug.Conn

  import Conn, only: [halt: 1]
  import Phoenix.Controller, only: [redirect: 2]

  @behaviour Plug

  @impl Plug
  def init(_opts), do: []

  @impl Plug
  def call(conn, _opts) do
    conn
    |> Session.is_signed_in?()
    |> auth_reply(conn)
  end

  defp auth_reply(true, conn), do: Session.restore(conn)

  defp auth_reply(false, conn) do
    conn
    |> redirect(to: Routes.session_path(conn, :form, RedirectTarget.from_original_request!(conn)))
    |> halt()
  end
end
