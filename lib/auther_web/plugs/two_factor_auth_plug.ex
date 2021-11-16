defmodule AutherWeb.TwoFactorAuthPlug do
  alias Auther.Accounts.{User, TwoFactorAuth}
  alias AutherWeb.RedirectTarget
  alias AutherWeb.Router.Helpers, as: Routes
  alias AutherWeb.Session
  alias Plug.Conn

  import Conn, only: [halt: 1]
  import Phoenix.Controller, only: [redirect: 2]

  @behaviour Plug

  @session_key "_auther_tfa_timestamp"

  @impl Plug
  def init(_opts), do: []

  @impl Plug
  def call(conn, _opts) do
    conn
    |> Session.current_user!()
    |> tfa_reply(conn)
  end

  # No TFA configured, do nothing.
  defp tfa_reply(%User{two_factor_auth: nil}, conn), do: conn

  defp tfa_reply(%User{two_factor_auth: %TwoFactorAuth{} = tfa}, conn) do
    if require_prompt?(conn, tfa) do
      do_redirect(conn)
    else
      reset_timer(conn)
    end
  end

  defp do_redirect(conn) do
    conn
    |> redirect(
      to:
        Routes.two_factor_auth_path(
          conn,
          :prompt,
          RedirectTarget.from_original_request!(conn)
        )
    )
    |> halt()
  end

  @doc """
  Signal that a TFA was provided and validated successfully.
  """
  @spec two_factor_auth_completed(Conn.t()) :: Conn.t()
  def two_factor_auth_completed(conn), do: reset_timer(conn)

  @doc """
  Test only: Change the internal TFA timer to the given timestamp. This will the be used to determine if the user should
   be prompted for a TFA token again.
  """
  @spec set_internal_timer(Conn.t(), integer()) :: Conn.t()
  def set_internal_timer(conn, time) when is_integer(time) do
    Conn.put_session(conn, @session_key, time)
  end

  defp reset_timer(conn), do: set_internal_timer(conn, now())

  defp require_prompt?(conn, %TwoFactorAuth{intrusiveness: intrussive}) do
    case Conn.get_session(conn, @session_key) do
      timestamp when is_integer(timestamp) -> do_require_prompt?(intrussive, now() - timestamp)
      nil -> true
    end
  end

  defp do_require_prompt?(:aggressive, seconds_ellapsed) do
    # 5min
    seconds_ellapsed > 5 * 60
  end

  defp do_require_prompt?(:balanced, seconds_ellapsed) do
    # 2h
    seconds_ellapsed > 2 * 60 * 60
  end

  defp do_require_prompt?(:required, _seconds_ellapsed) do
    # This will result in never querying for TFA because of time; only when the
    # `force: true` option is passed at Plug initialization.
    false
  end

  @spec now() :: integer()
  defp now, do: System.system_time(:second)
end
