defmodule Auther.OAuth.Store.RegistryTest do
  # For this test, we use the Registry (Supervisor and Registry) which are started with the App. Therefore, no further
  # setup is needed, BUT these tests can't run in parallel.
  use ExUnit.Case, async: false

  alias Auther.OAuth.Store.Registry

  test "inserting temporary data works" do
    key = "test1"
    data = %{test: "more"}
    Registry.insert(key, data)

    assert {:ok, data} = Registry.fetch(key)
  end

  test "data is auto removed after being accessed once" do
    key = "test1"
    Registry.insert(key, :nothing)

    assert {:ok, :nothing} = Registry.fetch(key)
    assert {:error, :entry_not_found} = Registry.fetch(key)
  end

  test "data is auto removed on expiry" do
    key = "test1"
    {:ok, pid} = Registry.insert(key, :something)

    send(pid, :expired)

    assert {:error, :entry_not_found} = Registry.fetch(key)
  end
end
