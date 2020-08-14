defmodule Auther.OAuth.Store.Entry do
  use GenServer, restart: :transient
  require Logger

  @expiry_time :timer.minutes(2)

  @impl GenServer
  def init(params) do
    schedule_expiry()
    {:ok, params}
  end

  defp schedule_expiry() do
    Process.send_after(self(), :expired, @expiry_time)
  end

  @impl GenServer
  def handle_info(:expired, state) do
    Logger.debug("Temporary credentials expired.")
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    Logger.debug("Temporary credentials accessed, removing them now.")
    {:stop, :normal, state, state}
  end

  #### CLIENT

  def start_link([name, data]) do
    GenServer.start_link(__MODULE__, data, name: name)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end
end
