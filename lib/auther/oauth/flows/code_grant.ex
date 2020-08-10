defmodule Auther.OAuth.Flows.CodeGrant do
  alias Auther.OAuth.{Request, Process}

  @spec auth_request(request :: Request.t()) :: Process.result()
  def auth_request(_request) do
    :ok
  end
end
