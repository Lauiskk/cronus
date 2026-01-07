defmodule Cronus.Monitoring.Supervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_worker(config) do
    spec = {Cronus.Monitoring.Worker, config}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
