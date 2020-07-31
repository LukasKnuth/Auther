defmodule Auther.OAuth.Client do

  @type t :: %__MODULE__{
              client_id: String.t,
              name: String.t,
              url: String.t,
              scopes: list(String.t),
              policies: %{String.t => any}
             }

  @enforce_keys [:client_id, :name, :url]
  defstruct client_id: nil,
            name: nil,
            url: nil,
            scopes: [],
            policies: %{}

  # Parse all client definitions at "priv/clients" at compile-time
  @lookup Auther.OAuth.Client.Parser.parse!()

  @spec fetch(client_id :: String.t) :: {:ok, %__MODULE__{}} | :error
  def fetch(client_id) do
    Map.fetch(@lookup, client_id)
  end

end