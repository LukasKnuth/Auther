defmodule Auther.Users.UserTest do
  use Auther.DataCase

  alias Auther.Users.User
  alias Ecto.Changeset

  describe "#changeset/2" do
    test "trims display_name before insert" do
      changeset = User.changeset(%Auther{}, %{email: "test@user.de", display_name: "  Peter "})

      assert changeset.valid?
      assert Changeset.fetch_field!(:display_name) = "Petedr"
    end
  end
end
