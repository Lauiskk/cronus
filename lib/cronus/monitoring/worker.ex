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
      id: args.id,
      url: args.url,
      interval: args.interval || 60_000,
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

    {_verdict, code, latency} =
      case Checker.check(state.url) do
        {:ok, code, latency} -> {:online, code, latency}
        {:error, code, latency} -> {:offline, code, latency}
      end

    site = Cronus.Repo.get!(Cronus.Sites.Site, state.id)
    checked_at = DateTime.utc_now()

    Cronus.Sites.Site.changeset(site, %{
      last_status: code,
      last_latency: latency,
      last_checked_at: checked_at
    })
    |> Cronus.Repo.update()

    Phoenix.PubSub.broadcast(Cronus.PubSub, "monitoring", {:check_result, %{
      site_id: state.id,
      status: code,
      latency: latency,
      checked_at: checked_at
    }})

    Process.send_after(self(), :tick, state.interval)

    {:noreply, state}
  end
end
