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

  defp tfa_reply(%User{two_factor_auth: %TwoFactorAuth{}}, conn) do
    if require_prompt?(conn) do
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
    else
      reset_timer(conn)
    end
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

  defp require_prompt?(conn) do
    case Conn.get_session(conn, @session_key) do
      # todo make variabel!
      timestamp when is_integer(timestamp) -> now() - timestamp > 30
      nil -> true
    end
  end

  @spec now() :: integer()
  defp now, do: System.system_time(:second)
end
