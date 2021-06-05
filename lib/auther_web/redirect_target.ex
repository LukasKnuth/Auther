defmodule AutherWeb.RedirectTarget do
  @moduledoc """
  A collection of helpers to handle the common "pass a URI to be redirected after an action"-pattern.
  """

  alias AutherWeb.Router.Helpers, as: Routes

  @type url_param :: keyword()
  @type relative_url :: String.t()
  @type options :: [key: String.t(), fallback: String.t()]

  @default_key "target"

  @spec fetch(Plug.Conn.t(), options()) :: {:valid, relative_url()} | :invalid | :error
  def fetch(conn, options \\ []) do
    key = param_key(options)

    with {:ok, target} <- fetch_query_param(conn, key) do
      validate_target(target)
    else
      :error -> :error
    end
  end

  @doc """
  Returns the target route from the query-parameter or a fallback route to navigate to, after the controller-action
   is done.
  """
  @spec get(Plug.Conn.t(), options()) :: relative_url()
  def get(conn, options \\ []) do
    case fetch(conn, options) do
      {:valid, target} -> target
      _else -> fallback_route(conn, options)
    end
  end

  @doc """
  Validate and create url parameters to be used with route-helpers from the given target URL.
  """
  @spec as_url_param(relative_url(), options()) :: {:ok, url_param()} | :invalid
  def as_url_param(target, options \\ []) do
    name = param_key(options)

    case validate_target(target) do
      {:valid, target} -> {:ok, [{name, target}]}
      :invalid -> :invalid
    end
  end

  @spec as_url_param!(relative_url(), options()) :: url_param()
  def as_url_param!(target, options \\ []) do
    case as_url_param(target, options) do
      {:ok, url_param} -> url_param
      :invalid -> raise ArgumentError, message: "Given route is not valid as a redirect target"
    end
  end

  @doc """
  Take path and query from the request in the Connection and turn it into a target parameter.
  """
  @spec from_original_request!(Plug.Conn.t(), options()) :: url_param()
  def from_original_request!(conn, options \\ []) do
    target =
      if String.length(conn.query_string) > 0 do
        conn.request_path <> "?" <> conn.query_string
      else
        conn.request_path
      end

    as_url_param!(target, options)
  end

  @doc """
  Extract, validate and return the redirect target for use as a query parameter in a route-helper.
  """
  @spec query_to_url_param(Plug.Conn.t(), options()) :: url_param()
  def query_to_url_param(conn, options \\ []) do
    key = param_key(options)

    with {:ok, target} <- fetch_query_param(conn, key),
         {:valid, target} <- validate_target(target) do
      [{key, target}]
    else
      _ -> []
    end
  end

  defp param_key(options), do: Keyword.get(options, :key, @default_key)

  defp fallback_route(conn, options) do
    Keyword.get_lazy(options, :fallback, fn -> Routes.account_path(conn, :show) end)
  end

  defp fetch_query_param(conn, key) when is_binary(key), do: Map.fetch(conn.query_params, key)

  defp fetch_query_param(conn, key), do: fetch_query_param(conn, to_string(key))

  defp validate_target(target) do
    with %{host: nil, scheme: nil, authority: nil, path: path} = uri <- URI.parse(target) do
      case validate_path(path) do
        :valid ->
          {:valid, target}

        {:sanitized, path} ->
          uri = Map.put(uri, :path, path)
          {:valid, URI.to_string(uri)}

        :invalid ->
          :invalid
      end
    else
      _ -> :invalid
    end
  end

  defp validate_path(path) do
    cond do
      # todo maybe get something more suffisticated in here?>
      String.contains?(path, "../") -> :invalid
      !String.starts_with?(path, "/") -> {:sanitized, "/" <> path}
      true -> :valid
    end
  end
end
