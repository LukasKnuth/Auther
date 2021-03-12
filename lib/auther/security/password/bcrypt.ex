defmodule Auther.Security.Password.Bcrypt do
  @behaviour Auther.Security.Password

  alias Auther.Accounts.User

  @impl true
  def hash(password), do: Bcrypt.hash_pwd_salt(password)

  @impl true
  def verify(given, %User{password_hash: stored}), do: verify(given, stored)

  def verify(given, stored) when is_bitstring(stored), do: Bcrypt.verify_pass(given, stored)
end
