defmodule AutherWeb.SessionTest do
  use AutherWeb.ConnCase

  alias Auther.Accounts
  alias Auther.Security.Password.Mock, as: MockPassword
  alias AutherWeb.Session
  alias Plug.Conn

  @user_attrs %{
    email: "some@person.com",
    name: "Somebody",
    password: "test1234",
    password_confirmation: "test1234"
  }

  setup do
    Mox.stub(MockPassword, :hash, &Auther.Security.Password.Bcrypt.hash/1)
    Mox.stub(MockPassword, :verify, &Auther.Security.Password.Bcrypt.verify/2)
    user = user_fixture!()
    conn = Session.sign_in(session_conn(), user)

    [user: user, conn: conn]
  end

  describe "authenticate_user/2" do
    test "returns authenticated user if username/password are valid", %{user: user} do
      assert {:ok, ^user} = Session.authenticate_user(user.email, "test1234")
    end

    test "returns :error if username is found but password doesn't match", %{user: user} do
      assert {:error, :invalid_combination} = Session.authenticate_user(user.email, "incorrect")
    end

    test "returns :error if username not found" do
      assert {:error, :invalid_combination} = Session.authenticate_user("doesnt@exist.com", "irrelevant")
    end
  end

  describe "restore/1" do
    test "loads the user so that it's accessible again", %{user: user} do
      conn = session_conn()
      |> Conn.put_session("_auther_session_user", %{user_id: user.id})
      |> Session.restore()

      assert Session.is_signed_in?(conn) == true
      assert Session.current_user!(conn) == user
    end

    test "does nothing if no user info is found in session" do
      fresh_conn = session_conn()
      restored_conn = Session.restore(fresh_conn)

      assert fresh_conn == restored_conn
    end
  end

  describe "sign_in/2" do
    test "writes user_id into session and user-Struct into privates", %{user: user} do
      conn = Session.sign_in(session_conn(), user)

      assert Session.is_signed_in?(conn) == true
      assert Session.current_user!(conn) == user
    end
  end

  describe "sign_out/1" do
    test "clears the login state from the session", %{user: user, conn: conn} do
      assert Session.is_signed_in?(conn) == true
      assert Session.current_user!(conn) == user

      conn = Session.sign_out(conn)

      assert Session.is_signed_in?(conn) == false
      assert Session.current_user(conn) == :error
    end
  end

  describe "current_user/1" do
    test "fetches current user from valid session", %{user: user, conn: conn} do
      assert Session.current_user(conn) == {:ok, user}
    end

    test "returns error for invalid session" do
      assert Session.current_user(session_conn()) == :error
    end
  end

  describe "current_user!/1" do
    test "fetches current user from valid session", %{user: user, conn: conn} do
      assert Session.current_user!(conn) == user
    end

    test "returns error for invalid session" do
      assert_raise KeyError, fn ->
        Session.current_user!(session_conn())
      end
    end
  end

  describe "is_signed_in?/1" do
    test "returns true for session with authenticated user", %{conn: conn} do
      assert Session.is_signed_in?(conn) == true
    end

    test "returns false for session without authenticated user" do
      assert Session.is_signed_in?(session_conn()) == false
    end
  end

  defp session_conn do
    build_conn()
    |> bypass_through(AutherWeb.Router, :browser)
    |> get("/")
  end

  defp user_fixture! do
    {:ok, user} = Accounts.create_user(@user_attrs)
    Map.put(user, :two_factor_auth, nil) # pretend like 2FA is preloaded
  end
end
