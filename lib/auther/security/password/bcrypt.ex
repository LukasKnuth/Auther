defmodule Auther.Security.Password.Bcrypt do
  @behaviour Auther.Security.Password

  alias Auther.Accounts.User

  @impl true
  def hash(password), do: Bcrypt.hash_pwd_salt(password)

  @impl true
  def verify(%User{password_hash: stored}, given), do: verify(stored, given)

  def verify(stored, given) when is_bitstring(stored), do: Bcrypt.verify_pass(given, stored)
end
