defmodule Auther.OAuth.Client.Parser do

  alias Auther.OAuth.Client

  @spec parse!() :: %{String.t => %Client{}}
  def parse!() do

    base_path = Path.join([:code.priv_dir(:auther), "clients"])

    base_path
    |> File.ls!()
    |> Enum.map(&parse_yaml!(Path.join(base_path, &1)))
    |> Enum.reduce(%{}, &parse_client!(&1, &2))
  end

  defp parse_yaml!(file) do
    file
    |> YamlElixir.read_all_from_file!()
    |> Enum.fetch!(0)
    |> Map.fetch!("client")
    |> Enum.fetch!(0)
  end

  defp parse_client!(%{"id" => id, "scopes" => scopes} = yaml, lookup) do
    yaml
    |> Map.delete("scopes")
    |> parse_client!(lookup)
    |> Map.update!(id, fn client -> %{client | scopes: scopes} end)
  end

  defp parse_client!(%{"id" => id, "policies" => policies} = yaml, lookup) do
    yaml
    |> Map.delete("policies")
    |> parse_client!(lookup)
    |> Map.update!(id, fn client -> %{client | policies: policies} end)
  end

  defp parse_client!(%{"name" => name, "id" => id, "url" => url}, lookup) do
    lookup
    |> Map.put(id, %Client{client_id: id, name: name, url: url})
  end

  defp parse_client!(yaml, _lookup), do: raise(CompileError, "YAML entry is invalid!")

end