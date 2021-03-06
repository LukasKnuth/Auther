defmodule AutherWeb.SessionControllerTest do
  use AutherWeb.ConnCase

  alias Auther.Accounts
  alias Auther.Accounts.User
  alias AutherWeb.Session

  setup :verify_on_exit!

  describe "GET #form" do
    test "returns the HTML form", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :form))

      assert html_response(conn, 200) =~ "Login form"
    end

    test "redirects to profile if user is already logged in", %{conn: conn} do
      conn =
        conn
        |> with_logged_in(fixture(:user))
        |> get(Routes.session_path(conn, :form))

      assert redirected_to(conn) == Routes.account_path(conn, :show)
    end
  end

  describe "POST #login" do
    test "without any parameters renders login form and flashes error", %{conn: conn} do
      conn = post(conn, Routes.session_path(conn, :login))

      assert html_response(conn, 200) =~ "Login form"
      assert get_flash(conn, :error) == "Unknown email/password combination"
      refute Session.is_signed_in?(conn)
    end

    test "with unkown email/password renders login form and flashes error", %{conn: conn} do
      conn =
        post(conn, Routes.session_path(conn, :login),
          email: "test@person.de",
          password: "irrelevant"
        )

      assert html_response(conn, 200) =~ "Login form"
      assert get_flash(conn, :error) == "Unknown email/password combination"
      refute Session.is_signed_in?(conn)
    end

    test "with valid email/password redirects and flashes info", %{conn: conn} do
      stub(Auther.Security.Password.Mock, :hash, &Auther.Security.Password.Bcrypt.hash/1)
      stub(Auther.Security.Password.Mock, :verify, &Auther.Security.Password.Bcrypt.verify/2)

      {:ok, %User{}} =
        Accounts.create_user(%{
          name: "test",
          email: "test@user.de",
          password: "testing",
          password_confirmation: "testing"
        })

      conn =
        post(conn, Routes.session_path(conn, :login), email: "test@user.de", password: "testing")

      assert redirected_to(conn) == Routes.account_path(conn, :show)
      assert get_flash(conn, :info) == "Succesfully logged in"
      assert Session.is_signed_in?(conn)
    end
  end

  describe "GET #logout" do
    test "clears session, flashes info and redirects", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :logout))

      assert redirected_to(conn) == Routes.session_path(conn, :form)
      assert get_flash(conn, :info) == "Succesfully logged out"
      refute Session.is_signed_in?(conn)
    end
  end
end
