defmodule AutherWeb.PageController do
  use AutherWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
