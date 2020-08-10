defmodule Auther.OAuth.ProcessTest do
  use Auther.DataCase

  alias Auther.Users
  alias Auther.Users.{Group}
  alias Auther.OAuth.{Process}

  describe "#auth_request/6" do
    setup do
      {:ok, group} =
        Users.create_group(%{
          name: "Testers",
          description: "Test Group",
          scopes: ["blog.draft_article"]
        })

      {:ok, user} =
        Users.create_user(%{
          email: "test@address.de",
          display_name: "Thomas",
          password: "abcd1234",
          password_confirmation: "abcd1234"
        })

      {:ok, user} = Users.user_set_groups(user, group)

      %{user: user, group: group}
    end

    test "returns a specifc error if the client isn't valid", %{user: user} do
      assert :error =
               Process.auth_request(
                 user,
                 "test",
                 "invalid",
                 "unimportant",
                 "blog.draft_article",
                 "state"
               )
    end

    test "does not accept relative redirect url", %{user: user} do
      assert {:error, {:redirect_url, :relative_url}} =
               Process.auth_request(
                 user,
                 "test",
                 "blog",
                 "/success",
                 "blog.draft_article",
                 "state"
               )
    end

    test "does not accept redirect url with fragment", %{user: user} do
      assert {:error, {:redirect_url, :fragment_forbidden}} =
               Process.auth_request(
                 user,
                 "test",
                 "blog",
                 "https://somewhere.com/#special",
                 "blog.draft_article",
                 "state"
               )
    end

    test "does not accept unknown oauth mode", %{user: user} do
      assert {:error, :unsupported_auth_request} =
               Process.auth_request(
                 user,
                 "unsupported",
                 "blog",
                 "http://success",
                 "blog.draft_article",
                 "state"
               )
    end
  end
end
