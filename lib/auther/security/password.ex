defmodule Auther.Security.Password do
  use Knigge, otp_app: :auther

  alias Auther.Accounts.User

  @type password :: String.t()
  @type hashed_password :: String.t()

  @doc "Hash and salt the given plain-text password for storage"
  @callback hash(password()) :: hashed_password()

  @doc "Compare the given plain-text password to the (hashed and salted) password from storage"
  @callback verify(password(), hashed_password() | User.t()) :: boolean()
end
