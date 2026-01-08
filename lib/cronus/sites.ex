defmodule Cronus.Sites do
  import Ecto.Query, warn: false
  alias Cronus.Repo
  alias Cronus.Sites.Site

  def list_sites do
    Repo.all(Site)
  end

  def get_site!(id), do: Repo.get!(Site, id)

  def create_site(attrs \\ %{}) do
    %Site{}
    |> Site.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, site} = result ->
        if site.active do
          Cronus.Monitoring.Supervisor.start_worker(site)
        end

        result

      error ->
        error
    end
  end

  def update_site(%Site{} = site, attrs) do
    site
    |> Site.changeset(attrs)
    |> Repo.update()
  end

  def delete_site(%Site{} = site) do
    Repo.delete(site)
  end

  def change_site(%Site{} = site, attrs \\ %{}) do
    Site.changeset(site, attrs)
  end
end
