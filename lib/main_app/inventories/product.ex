defmodule MainApp.Inventories.Product do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :description, :slug], sortable: [:name, :slug]
  }

  schema "products" do
    field :slug, :string
    field :name, :string
    field :description, :string

    timestamps()
  end

  def changeset(product, attrs \\ %{}) do
    product
    |> cast(attrs, [:slug, :name, :description])
    |> validate_required([:slug, :name])
  end
end
