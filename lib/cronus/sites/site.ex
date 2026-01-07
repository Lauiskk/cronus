defmodule Cronus.Sites.Site do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sites" do
    field :url, :string
    field :name, :string
    field :interval, :integer
    field :active, :boolean, default: false
    field :last_status, :integer
    field :last_latency, :integer
    field :last_checked_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(site, attrs) do
    site
    |> cast(attrs, [
      :url,
      :name,
      :interval,
      :active,
      :last_status,
      :last_latency,
      :last_checked_at
    ])
    |> validate_required([:url, :name, :interval, :active])
  end
end
