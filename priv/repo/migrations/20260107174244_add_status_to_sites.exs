defmodule Cronus.Repo.Migrations.AddStatusToSites do
  use Ecto.Migration

  def change do
    alter table(:sites) do
      add :last_status, :integer
      add :last_latency, :integer
      add :last_checked_at, :utc_datetime
    end
  end
end
