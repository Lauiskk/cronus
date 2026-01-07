defmodule Cronus.Monitoring.Hydrator do
  use Task, restart: :temporary

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  import Ecto.Query

  def run do
    Cronus.Repo.all(from s in Cronus.Sites.Site, where: s.active == true)
    |> Enum.each(fn site ->
      Cronus.Monitoring.Supervisor.start_worker(%{
        id: site.id,
        url: site.url,
        interval: site.interval
      })
    end)
  end
end
