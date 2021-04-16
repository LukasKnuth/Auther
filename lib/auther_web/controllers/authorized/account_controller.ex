defmodule AutherWeb.Authorized.AccountController do
  use AutherWeb, :controller

  alias Auther.Accounts
  alias Auther.Accounts.User
  alias AutherWeb.Session

  def show(conn, _params), do: render(conn, :show)

  def edit(conn, _params) do
    user = Session.current_user!(conn)
    render(conn, :edit, changeset: User.changeset_for_update(user), action: update_action(conn))
  end

  def update(conn, params) do
    conn
    |> Session.current_user!()
    |> Accounts.update_user(Map.get(params, "user", %{}))
    |> case do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Updated account information"))
        |> redirect(to: Routes.account_path(conn, :show))

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset, action: update_action(conn))
    end
  end

  defp update_action(conn), do: Routes.account_path(conn, :update)
end
