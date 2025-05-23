defmodule MainApp.Inventories.Product do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :description, :sku, :search],
    sortable: [:name, :sku],
    adapter_opts: [
      custom_fields: [
        search: [
          filter: {MainApp.Inventories.FlopFilter, :search_products_filter, []},
          ecto_type: :string
        ]
      ]
    ]
  }

  schema "products" do
    field :sku, :string
    field :name, :string
    field :description, :string
    field :source, :string
    field :external_id, :string
    field :metadata, :map
    belongs_to :dummy_product_import, MainApp.ExternalInventories.DummyProductImport

    timestamps()
  end

  def changeset(product, attrs \\ %{}) do
    product
    |> cast(attrs, [:sku, :name, :description, :source, :external_id])
    |> validate_required([:sku, :name])
  end
end
