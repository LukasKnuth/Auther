defmodule AutherWeb.Authorized.AccountController do
  use AutherWeb, :controller

  def show(conn, _params) do
    render(conn, :show)
  end
end
