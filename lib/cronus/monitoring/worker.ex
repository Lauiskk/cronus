defmodule Cronus.Monitoring.Worker do
  use GenServer
  require Logger

  defstruct [:id, :url, :interval, :status, :last_check]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
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
    Logger.info("Executando verificação em #{state.url}...")

    Process.send_after(self(), :tick, state.interval)

    {:noreply, state}
  end

end
