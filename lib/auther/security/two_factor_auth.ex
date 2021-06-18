defmodule Auther.Security.TwoFactorAuth do
  use Knigge, otp_app: :auther

  alias Auther.Accounts.User

  @moduledoc """
  Allows setting up and using a means of authenticating a user by a secondary factor (2FA) through a one-time password.
  """

  @type pre_shared_secret :: String.t()
  @type one_time_password :: String.t()
  @type otpauth_uri :: String.t()
  @type fallback_code :: String.t()
  @type hashed_fallback_code :: String.t()
  @type validate_response :: :invalid | {:valid, :otp | {:fallback, list(hashed_fallback_code())}}

  @doc "Generates a secret to be shared between Auther and the user to generate one-time passwords from"
  @callback generate_secret() :: pre_shared_secret()

  @doc "Checks if the given one-time password is valid for the pre-shared secret"
  @callback validate(one_time_password(), pre_shared_secret(), list(hashed_fallback_code())) :: validate_response()

  @doc "Creates a otpauth:// schema URI for easy setup via QRCodes"
  @callback otpauth_uri(pre_shared_secret(), User.t()) :: otpauth_uri()

  @doc "Generates a fallback code, to be given to the user in plain for use if TFA isn't avaibale"
  @callback generate_fallback() :: fallback_code()

  @doc "Hashes the plain fallback code for storage and further usage by the application"
  @callback hash_fallback(fallback_code()) :: hashed_fallback_code()
end
