defmodule Auther.Security.TwoFactorAuth do
  use Knigge, otp_app: :auther

  alias Auther.Accounts.User

  @moduledoc """
  Allows setting up and using a means of authenticating a user by a secondary factor (2FA) through a one-time password.
  """

  @type pre_shared_secret :: String.t()
  @type one_time_password :: String.t()
  @type otpauth_uri :: String.t()

  @doc "Generates a secret to be shared between Auther and the user to generate one-time passwords from"
  @callback generate_secret() :: pre_shared_secret()

  @doc "Checks if the given one-time password is valid for the pre-shared secret"
  @callback valid?(pre_shared_secret(), one_time_password()) :: boolean()

  @doc "Creates a otpauth:// schema URI for easy setup via QRCodes"
  @callback otpauth_uri(pre_shared_secret(), User.t()) :: otpauth_uri()
end
