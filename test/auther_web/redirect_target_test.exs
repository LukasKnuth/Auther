defmodule AutherWeb.RedirectTargetTest do
  use AutherWeb.ConnCase

  alias AutherWeb.RedirectTarget

  describe "fetch/2" do
    test "returns :valid and route if target is found and valid" do
      conn = test_conn(target: "some/where")
      assert RedirectTarget.fetch(conn) == {:valid, "some/where"}
    end

    test "returns :valid and route for custom query-param name (string or atom)" do
      conn = test_conn(go_to: "another/place")
      assert RedirectTarget.fetch(conn, key: :go_to) == {:valid, "another/place"}
      assert RedirectTarget.fetch(conn, key: "go_to") == {:valid, "another/place"}
    end

    test "returns :error if target isn't found in query-params" do
      conn = test_conn(go_to: "some/route/here")
      assert RedirectTarget.fetch(conn) == :error
    end

    test "returns :invalid if fallback target is absolute" do
      conn = test_conn(target: "http://id.codeisland.org/test")
      assert RedirectTarget.fetch(conn) == :invalid
    end

    test "returns :invalid if fallback target is external URL" do
      conn = test_conn(target: "http://google.com")
      assert RedirectTarget.fetch(conn) == :invalid
    end

    test "returns :invalid if fallback target is traversing directories" do
      conn = test_conn(target: "somethign/../../admin")
      assert RedirectTarget.fetch(conn) == :invalid
    end
  end

  describe "get/2" do
    test "returns the target route from the query-parameters" do
      assert RedirectTarget.get(test_conn(target: "some/other/route")) ==
               "some/other/route"
    end

    test "returns the target route for different key-parameter" do
      conn = test_conn(goal: "another/route")

      assert RedirectTarget.get(conn, key: :goal) == "another/route"
      assert RedirectTarget.get(conn, key: "goal") == "another/route"
    end

    test "returns the fallback route if no target is in the query-parameters", %{conn: conn} do
      assert RedirectTarget.get(conn, fallback: "fb") == "fb"
    end
  end

  describe "as_url_param/2" do
    test "returns :valid and url-param for valid target route", %{conn: conn} do
      route = Routes.session_path(conn, :form)
      assert RedirectTarget.as_url_param(route) == {:ok, [{"target", route}]}
    end

    test "returns :invalid for invalid target route" do
      assert RedirectTarget.as_url_param("http://google.com") == :invalid
    end
  end

  describe "as_url_param!/2" do
    test "returns url-param for valid target route", %{conn: conn} do
      route = Routes.session_path(conn, :form)
      assert RedirectTarget.as_url_param!(route) == [{"target", route}]
    end

    test "raises ArgumentError for invalid target route" do
      assert_raise ArgumentError, fn ->
        RedirectTarget.as_url_param!("http://google.com")
      end
    end
  end

  describe "query_to_url_param/2" do
    test "returns the target as keyword list from query-parameters" do
      conn = test_conn(target: "some/where")
      assert RedirectTarget.query_to_url_param(conn) == [{"target", "some/where"}]
    end

    test "returns the target for different key-parameter" do
      conn = test_conn(go_to: "a/route")

      assert RedirectTarget.query_to_url_param(conn, key: :go_to) == [{:go_to, "a/route"}]
      assert RedirectTarget.query_to_url_param(conn, key: "go_to") == [{"go_to", "a/route"}]
    end

    test "returns empty keyword list if target not in query-parameters" do
      conn = test_conn()
      assert RedirectTarget.query_to_url_param(conn) == []
    end

    test "returns empty keyword list if target isn't valid" do
      conn = test_conn(target: "http://pishing.com/steal")
      assert RedirectTarget.query_to_url_param(conn) == []
    end
  end

  defp test_conn(params \\ []) do
    build_conn(:get, "/test", params)
  end
end
