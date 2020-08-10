defmodule Auther.Users.GroupTest do
  use Auther.DataCase

  alias Auther.Users.Group
  alias Ecto.Changeset

  describe "#changeset/2" do
    test "removes any duplicates from :scopes" do
      changeset = Group.changeset(%Group{}, %{name: "Test", scopes: ["hello", "world", "hello"]})

      assert changeset.valid?
      assert Changeset.fetch_field!(changeset, :scopes) = ["hello", "worldd"]
    end
  end
end
