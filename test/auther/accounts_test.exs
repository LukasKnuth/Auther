defmodule Auther.AccountsTest do
  use Auther.DataCase

  alias Auther.Accounts
  alias Auther.Accounts.User

  @valid_attrs %{email: "some email", name: "some name", password_hash: "some password_hash"}
  @update_attrs %{email: "some updated email", name: "some updated name", password_hash: "some updated password_hash"}
  @invalid_attrs %{email: nil, name: nil, password_hash: nil}

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
      assert user.password_hash == "some password_hash"
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
      assert user.password_hash == "some updated password_hash"
    end

    test "with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
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

  describe "change_user/1" do
    test "returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
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
