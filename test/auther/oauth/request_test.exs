defmodule Auther.Oauth.ClientTest do
  use Auther.DataCase

  alias Auther.OAuth.Client

  describe "compiletime lookup" do

    test "has expected entry" do
      assert {:ok, %Client{client_id: "blog", url: "https://codeisland.org", name: "Blog CMS"}} = Client.fetch("blog")
    end

  end
end