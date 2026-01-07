defmodule Cronus.Monitoring.Worker do
  use GenServer
  require Logger
  alias Cronus.Monitoring.Checker

  defstruct [:id, :url, :interval, :status, :last_check]

  def start_link(config) do
    name = {:via, Registry, {Cronus.Registry, config.url}}
    GenServer.start_link(__MODULE__, config, name: name)
  end

  @impl true
  @spec init(nil | maybe_improper_list() | map()) ::
          {:ok,
           %Cronus.Monitoring.Worker{
             id: any(),
             interval: any(),
             last_check: nil,
             status: :unknown,
             url: any()
           }}
  def init(args) do
    state = %__MODULE__{
      id: args[:id],
      url: args[:url],
      interval: args[:interval] || 60_000,
      status: :unknown,
      last_check: nil
    }

    Logger.info("Iniciando monitor para: #{state.url}")

    send(self(), :tick)

    {:ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    Logger.info("Verificando #{state.url}...")
    result = Checker.check(state.url)

    state =
      case result do
        {:ok, status, milliseconds} ->
          Logger.info("#{state.url} está online (#{status} - #{milliseconds}ms)")
          %{state | status: :online, last_check: DateTime.utc_now()}

        {:error, status, milliseconds} ->
          Logger.info("#{state.url} está offline (#{status} - #{milliseconds}ms)")
          %{state | status: :offline, last_check: DateTime.utc_now()}
      end

    Process.send_after(self(), :tick, state.interval)

    Phoenix.PubSub.broadcast(Cronus.PubSub, "monitoring", {:check_result, result})
    {:noreply, state}
  end
end
