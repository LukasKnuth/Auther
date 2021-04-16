defmodule AutherWeb.SessionTest do
  use AutherWeb.ConnCase

  alias AutherWeb.Session
  alias Plug.Conn

  setup %{conn: conn} do
    Mox.stub(Auther.Security.Password.Mock, :verify, &Auther.Security.Password.Bcrypt.verify/2)
    user = fixture(:user)
    logged_in_conn = with_logged_in(conn, user)
    session_conn = with_session(conn)
    {:ok, %{logged_in_conn: logged_in_conn, conn: session_conn, user: user}}
  end

  describe "authenticate_user/2" do
    test "returns authenticated user if username/password are valid", %{user: user} do
      assert {:ok, ^user} = Session.authenticate_user(user.email, "asdf1234")
    end

    test "returns :error if username is found but password doesn't match", %{user: user} do
      assert {:error, :unknown_combination} = Session.authenticate_user(user.email, "incorrect")
    end

    test "returns :error if username not found" do
      assert {:error, :unknown_combination} =
               Session.authenticate_user("doesnt@exist.com", "irrelevant")
    end
  end

  describe "restore/1" do
    test "loads the user so that it's accessible again", %{conn: conn, user: user} do
      conn =
        conn
        |> Conn.put_session("_auther_session_user", %{user_id: user.id})
        |> Session.restore()

      assert Session.is_signed_in?(conn) == true
      assert Session.current_user!(conn) == user
    end

    test "does nothing if no user info is found in session", %{conn: conn} do
      restored_conn = Session.restore(conn)

      assert conn == restored_conn
    end
  end

  describe "sign_in/2" do
    test "writes user_id into session and user-Struct into privates", %{conn: conn, user: user} do
      conn = Session.sign_in(conn, user)

      assert Session.is_signed_in?(conn) == true
      assert Session.current_user!(conn) == user
    end
  end

  describe "sign_out/1" do
    test "clears the login state from the session", %{user: user, logged_in_conn: conn} do
      assert Session.is_signed_in?(conn) == true
      assert Session.current_user!(conn) == user

      conn = Session.sign_out(conn)

      assert Session.is_signed_in?(conn) == false
      assert Session.current_user(conn) == :error
    end
  end

  describe "current_user/1" do
    test "fetches current user from valid session", %{user: user, logged_in_conn: conn} do
      assert Session.current_user(conn) == {:ok, user}
    end

    test "returns error for invalid session", %{conn: conn} do
      assert Session.current_user(conn) == :error
    end
  end

  describe "current_user!/1" do
    test "fetches current user from valid session", %{user: user, logged_in_conn: conn} do
      assert Session.current_user!(conn) == user
    end

    test "returns error for invalid session", %{conn: conn} do
      assert_raise KeyError, fn ->
        Session.current_user!(conn)
      end
    end
  end

  describe "is_signed_in?/1" do
    test "returns true for session with authenticated user", %{logged_in_conn: conn} do
      assert Session.is_signed_in?(conn) == true
    end

    test "returns false for session without authenticated user", %{conn: conn} do
      assert Session.is_signed_in?(conn) == false
    end
  end
end
