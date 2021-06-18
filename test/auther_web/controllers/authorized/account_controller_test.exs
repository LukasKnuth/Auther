defmodule AutherWeb.Authorized.AccountControllerTest do
  use AutherWeb.ConnCase

  alias Auther.Accounts

  setup :verify_on_exit!

  setup %{conn: conn} do
    user = fixture(:user)
    conn = with_logged_in(conn, user)
    {:ok, %{logged_in_conn: conn, user: user}}
  end

  describe "GET #show" do
    test_auth_required(get: account_path(:show))

    test "renders user information if logged in", %{logged_in_conn: conn, user: user} do
      conn = get(conn, Routes.account_path(conn, :show))

      assert html_response(conn, 200) =~ html_escape(user.name)
    end
  end

  describe "GET #edit" do
    test_auth_required(get: account_path(:edit))

    test "renders edit form if logged in", %{logged_in_conn: conn} do
      conn = get(conn, Routes.account_path(conn, :edit))

      assert html_response(conn, 200) =~ "Edit Account"
    end
  end

  describe "PUT #update" do
    test_auth_required(put: account_path(:update))

    test "updates user info, flashes and redirects", %{logged_in_conn: conn, user: previous_user} do
      conn =
        put(conn, Routes.account_path(conn, :update), %{
          user: %{name: "Peter", email: "peter@test.de"}
        })

      assert redirected_to(conn) == Routes.account_path(conn, :show)
      assert get_flash(conn, :info) == "Updated account information"

      user = Accounts.get_user!(previous_user.id)
      assert user.name == "Peter"
      assert user.email == "peter@test.de"
      assert user.password_hash == previous_user.password_hash
    end

    test "updates password, falshes and redirects", %{logged_in_conn: conn, user: previous_user} do
      stub(Auther.Security.Password.Mock, :hash, fn _ -> "pretend_its_a_hash" end)

      conn =
        put(conn, Routes.account_path(conn, :update), %{
          user: %{password: "test1234", password_confirmation: "test1234"}
        })

      assert redirected_to(conn) == Routes.account_path(conn, :show)
      assert get_flash(conn, :info) == "Updated account information"

      user = Accounts.get_user!(previous_user.id)
      assert user.name == previous_user.name
      assert user.email == previous_user.email
      assert user.password_hash == "pretend_its_a_hash"
    end

    test "redirects without changes if no arguments are given", %{
      logged_in_conn: conn,
      user: previous_user
    } do
      conn = put(conn, Routes.account_path(conn, :update))

      assert redirected_to(conn) == Routes.account_path(conn, :show)
      assert Accounts.get_user!(previous_user.id) == previous_user
    end

    test "re-renders form with errors if invalid info is entered", %{
      logged_in_conn: conn,
      user: previous_user
    } do
      conn =
        put(conn, Routes.account_path(conn, :update), %{user: %{name: "", email: "notanemail"}})

      assert html_response(conn, 200) =~ html_escape("can't be blank")

      assert Accounts.get_user!(previous_user.id) == previous_user
    end

    test "re-renders form with errors if passwords dont match", %{
      logged_in_conn: conn,
      user: previous_user
    } do
      conn =
        put(conn, Routes.account_path(conn, :update), %{
          user: %{password: "a", password_confirmation: "b"}
        })

      assert html_response(conn, 200) =~ html_escape("does not match confirmation")

      assert Accounts.get_user!(previous_user.id) == previous_user
    end
  end
end
