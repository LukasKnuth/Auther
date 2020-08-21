defmodule Auther.JWT.Token do
  use Joken.Config, default_signer: :jwt_token

  @issuer "Auther"

  def token_config do
    default_claims(iss: @issuer, skip: [:aud])
  end

  @spec for_user_client(user :: User, client :: Client) :: {:ok, String.t()}
  def for_user_client(user, client) do
    %{"aud" => client.url, "sub" => user.id}
    |> generate_and_sign()
  end
end
