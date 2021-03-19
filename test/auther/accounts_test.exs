defmodule Auther.AccountsTest do
  use Auther.DataCase

  import Mox

  alias Auther.Accounts
  alias Auther.Accounts.User
  alias Auther.Security.Password.Mock, as: MockPassword

  @pw_hash "$2b$12$rMFYMFy91qV6KTPclubTVOL9gpO55.JRWDRlaZccqsdbIXZA6O8Gi"
  @valid_attrs %{
    email: "some email",
    name: "some name",
    password: "asdf1234",
    password_confirmation: "asdf1234"
  }
  @update_attrs %{email: "some updated email", name: "some updated name"}
  @invalid_attrs %{email: nil, name: nil, password_hash: "anything"}

  setup do
    stub(MockPassword, :hash, fn _ -> @pw_hash end)
    :ok
  end

  describe "get_user!/1" do
    test "returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end
  end

  describe "create_user/1" do
    test "with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.name == "some name"
      assert user.password_hash == @pw_hash
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end
  end

  describe "update_user/2" do
    test "with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.name == "some updated name"
      # unchanged
      assert user.password_hash == @pw_hash
    end

    test "with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "with password_hash doesn't change stored password_hash" do
      user = user_fixture()
      assert {:ok, %User{} = changed_user} = Accounts.update_user(user, %{password_hash: "other"})
      assert user == changed_user
    end
  end

  describe "change_password/2" do
    @test_pw_hash "$2b$12$hAtV1nhmVf/Ij94r/6rGJupCABIcvGK4Yv7hu3bW30KuVCJGdmsOG"

    test "with password and confirm_password updates the user" do
      MockPassword
      |> expect(:hash, fn _ -> @pw_hash end)
      |> expect(:hash, fn _ -> @test_pw_hash end)

      user = user_fixture()

      assert {:ok, %User{} = user} =
               Accounts.change_password(user, %{password: "test", password_confirmation: "test"})

      assert user.password_hash == @test_pw_hash
    end

    test "with non-matching password and confirm_passowrd returns error changeset" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.change_password(user, %{password: "test", password_confirmation: "other"})

      assert user == Accounts.get_user!(user.id)
    end

    test "without confirm_password returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.change_password(user, %{password: "test"})
      assert user == Accounts.get_user!(user.id)
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end
  end

  defp user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Accounts.create_user()

    user
  end
end
