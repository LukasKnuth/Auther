defmodule AutherWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AutherWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Auther.Fixtures
      import AutherWeb.ConnCase

      import Plug.HTML, only: [html_escape: 1]

      alias AutherWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint AutherWeb.Endpoint
    end
  end

  def with_session(conn, session \\ %{}) do
    Plug.Test.init_test_session(conn, session)
  end

  def with_logged_in(conn, %Auther.Accounts.User{} = user) do
    conn
    |> with_session()
    |> AutherWeb.Session.sign_in(user)
  end

  @doc """
  ## Examples

    iex> test_auth_required(get: session_path(:show))
    iex> test_auth_required(post: session_path(:login))
  """
  defmacro test_auth_required([{method, {name, _, args}}]) do
    quote do
      test "if not authenticated, redirects to login", %{conn: conn} do
        alias AutherWeb.Router.Helpers, as: Routes
        path = apply(Routes, unquote(name), [conn | unquote(args)])
        conn = Phoenix.ConnTest.dispatch(conn, @endpoint, unquote(method), path)
        params = AutherWeb.RedirectTarget.as_url_param!(path)

        assert redirected_to(conn) == Routes.session_path(conn, :form, params)
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Auther.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Auther.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
