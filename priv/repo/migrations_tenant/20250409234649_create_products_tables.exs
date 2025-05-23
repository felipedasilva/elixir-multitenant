defmodule MainApp.Repo.Migrations.CreateProductsTables do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :sku, :string
      add :name, :string
      add :price, :string, null: true
      add :description, :string, null: true
      add :external_id, :string, null: true
      add :source, :string, null: true
      add :metadata, :map, null: true

      add :dummy_product_import_id, references(:dummy_product_imports, on_delete: :nothing),
        null: true

      timestamps(type: :utc_datetime)
    end
  end
end
