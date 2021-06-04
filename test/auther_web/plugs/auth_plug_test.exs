defmodule AutherWeb.AuthPlugTest do
  use AutherWeb.ConnCase

  alias Auther.Accounts.User
  alias AutherWeb.Session

  test "redirects and halts if user isn't logged in", %{conn: conn} do
    conn = run_plug_with(conn)

    assert conn.halted == true
    assert redirected_to(conn) == Routes.session_path(conn, :form, target: "/")
  end

  test "restores the sessio if user is logged in", %{conn: conn} do
    conn = run_plug_with(conn, fixture(:user))

    assert conn.halted == false
    assert Session.is_signed_in?(conn) == true
    assert %User{} = Session.current_user!(conn)
  end

  defp run_plug_with(conn, user \\ nil) do
    conn
    |> maybe_put_session(user)
    |> AutherWeb.AuthPlug.call(AutherWeb.AuthPlug.init([]))
  end

  defp maybe_put_session(conn, nil), do: with_session(conn)

  defp maybe_put_session(conn, %User{} = user), do: with_logged_in(conn, user)
end
