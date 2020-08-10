defmodule Auther.OAuth.Process do
  alias Auther.OAuth.{Client, Flows.CodeGrant, Request}
  alias Auther.Users
  alias Auther.Users.User

  @type result :: :ok

  @spec auth_request(
          user :: User.t(),
          response_type :: String.t(),
          client_id :: String.t(),
          redirect_uri :: String.t() | nil,
          scope :: String.t() | nil,
          state :: String.t() | nil
        ) :: result
  def auth_request(user, response_type, client_id, redirect_uri, scope, state) do
    with {:ok, client} <- Client.fetch(client_id),
         request <- make_request(scope, client, user, response_type, redirect_uri, state),
         {:ok, request} <- ensure_scope(request),
         {:ok, request} <- validate_redirect(request),
         do: do_auth_request(request)
  end

  defp do_auth_request(%Request{response_type: "code"} = request) do
    CodeGrant.auth_request(request)
  end

  defp do_auth_request(_request) do
    {:error, :unsupported_auth_request}
  end

  defp make_request(scope, client, user, response_type, redirect_uri, state) do
    scope
    |> parse_scopes()
    |> Request.new(client, user, response_type, redirect_uri, state)
  end

  defp parse_scopes(scope) do
    scope
    |> String.split(" ", trim: true)
    |> MapSet.new()
  end

  defp ensure_scope(%Request{user: user, scopes: scopes} = request) do
    allowed_scopes = Users.get_scopes(user)
    missing_scopes = MapSet.difference(scopes, allowed_scopes)

    if MapSet.size(missing_scopes) > 0 do
      {:error, {:missing_scopes, MapSet.to_list(missing_scopes)}}
    else
      {:ok, request}
    end
  end

  defp validate_redirect(%Request{redirect_uri: redirect_uri} = request) do
    uri = URI.parse(redirect_uri)

    cond do
      uri.host == nil -> {:error, {:redirect_url, :relative_url}}
      uri.fragment != nil -> {:error, {:redirect_url, :fragment_forbidden}}
      true -> {:ok, request}
    end
  end
end
