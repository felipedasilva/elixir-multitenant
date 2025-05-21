defmodule MainApp.ExternalInventories.DummyProductImport do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :description], sortable: [:name]
  }

  schema "dummy_product_imports" do
    field :name, :string
    field :url, :string
    field :description, :string
    field :job_interval_in_seconds, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(dummy_product_import, attrs, _scope) do
    dummy_product_import
    |> cast(attrs, [:name, :url, :description, :job_interval_in_seconds])
    |> validate_required([:name, :url, :description, :job_interval_in_seconds])
  end
end
