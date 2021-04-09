defmodule AutherWeb.AuthPlugTest do
  use AutherWeb.ConnCase

  alias Auther.Accounts
  alias Auther.Accounts.User
  alias AutherWeb.Session

  test "redirects and halts if user isn't logged in" do
    conn = run_plug_with()

    assert conn.halted == true
    assert redirected_to(conn) == AutherWeb.Router.Helpers.session_path(conn, :form)
  end

  test "restores the sessio if user is logged in" do
    conn = run_plug_with(user_fixture())

    assert conn.halted == false
    assert Session.is_signed_in?(conn) == true
    assert %User{} = Session.current_user!(conn)
  end

  defp user_fixture do
    Mox.stub(Auther.Security.Password.Mock, :hash, fn _ -> "pretend_like_im_hashed" end)
    {:ok, user} = Accounts.create_user(%{name: "test", email: "test@user.de", password: "a", password_confirmation: "a"})
    user
  end

  defp run_plug_with(user \\ nil) do
    session_conn()
    |> maybe_put_session(user)
    |> AutherWeb.AuthPlug.call(
      AutherWeb.AuthPlug.init([])
    )
  end

  defp maybe_put_session(conn, nil), do: conn

  defp maybe_put_session(conn, %User{} = user), do: Session.sign_in(conn, user)
end
