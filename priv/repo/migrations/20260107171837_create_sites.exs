defmodule Cronus.Repo.Migrations.CreateSites do
  use Ecto.Migration

  def change do
    create table(:sites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string
      add :name, :string
      add :interval, :integer
      add :active, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
