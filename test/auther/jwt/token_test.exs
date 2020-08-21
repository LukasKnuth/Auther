defmodule Auther.JWT.TokenTest do
  use Auther.DataCase

  alias Auther.Users
  alias Auther.JWT.Token
  alias Auther.OAuth.Client

  describe "#create" do
    setup do
      {:ok, user} =
        Users.create_user(%{
          email: "test@address.de",
          display_name: "Peetre",
          password: "abcd1234",
          password_confirmation: "abcd1234"
        })

      {:ok, client} = Client.fetch("blog")

      %{user: user, client: client}
    end

    test "creates new token with expected audience and subject", %{user: user, client: client} do
      {:ok, token, _claims} = Token.for_user_client(user, client)

      subject = user.id

      {:ok, %{"iss" => "Auther", "aud" => "https://codeisland.org", "sub" => ^subject}} =
        Token.verify_and_validate(token)
    end

    test "the issued token expires after 2 minutes", %{user: user, client: client} do
      {:ok, token, _claims} = Token.for_user_client(user, client)

      issued_at = 719_871_000
      # 2min in seconds
      expiry = issued_at + 2 * 60 * 60

      {:ok, %{"iat" => ^issued_at, "nbf" => ^issued_at, "exp" => ^expiry}} =
        Token.verify_and_validate(token)
    end
  end
end
