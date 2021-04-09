defmodule AutherWeb.Session do
  @doc "Module to interact with a user session (via Plug.Conn object)."

  alias Auther.Accounts
  alias Auther.Accounts.User
  alias Auther.Security.Password
  alias Plug.Conn

  @session_key "_auther_session_user"

  @type session :: %{user_id: integer()}

  @spec authenticate_user(String.t(), String.t()) ::
          {:ok, %User{}} | {:error, :invalid_combination}
  def authenticate_user(email, password) do
    with {:ok, user} <- Accounts.get_user_by(email: email),
         true <- Password.verify(user, password) do
      {:ok, user}
    else
      _ -> {:error, :invalid_combination}
    end
  end

  @spec sign_in(Conn.t(), %User{}) :: Conn.t()
  def sign_in(conn, user) do
    conn
    |> Conn.put_session(@session_key, %{user_id: user.id})
    |> Conn.put_private(:auther_session_user, user)
  end

  @spec restore(Conn.t()) :: Conn.t()
  def restore(conn) do
    with %{user_id: id} <- Conn.get_session(conn, @session_key) do
      user = Accounts.get_user!(id)
      Conn.put_private(conn, :auther_session_user, user)
    else
      _ -> conn
    end
  end

  @spec sign_out(Conn.t()) :: Conn.t()
  def sign_out(conn) do
    conn
    |> Conn.configure_session(drop: true)
    |> Conn.clear_session()
    |> Conn.put_private(:auther_session_user, nil)
  end

  @spec current_user(Conn.t()) :: {:ok, %User{}} | :error
  def current_user(conn) do
    case Map.get(conn.private, :auther_session_user) do
      nil -> :error
      %User{} = user -> {:ok, user}
    end
  end

  @spec current_user!(Conn.t()) :: %User{}
  def current_user!(conn) do
    with {:ok, user} <- current_user(conn) do
      user
    else
      _ -> raise KeyError
    end
  end

  @spec is_signed_in?(Conn.t()) :: boolean()
  def is_signed_in?(conn) do
    case Conn.get_session(conn, @session_key) do
      nil -> false
      %{user_id: _id} -> true
    end
  end
end
