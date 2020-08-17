defmodule Auther.OAuth.Store.Registry do
  use Supervisor

  alias Auther.OAuth.Store.Entry

  @registry_name __MODULE__
  @dyn_supervisor_name __MODULE__.Supervisor

  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, [])
  end

  @impl Supervisor
  def init(_) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: @dyn_supervisor_name},
      {Registry, keys: :unique, name: @registry_name}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec insert(key :: String.t(), value :: any) :: any
  def insert(key, value) do
    name = name_for_key(key)

    DynamicSupervisor.start_child(@dyn_supervisor_name, {Entry, [name, value]})
  end

  defp name_for_key(key), do: {:via, Registry, {@registry_name, key}}

  @spec fetch(key :: String.t()) :: {:ok, any} | {:error, :entry_not_found}
  def fetch(key) do
    try do
      case Registry.lookup(@registry_name, key) do
        [{pid, _val}] -> {:ok, Entry.get(pid)}
        _ -> {:error, :entry_not_found}
      end
    catch
      :exit, _ -> {:error, :entry_not_found}
    end
  end
end
