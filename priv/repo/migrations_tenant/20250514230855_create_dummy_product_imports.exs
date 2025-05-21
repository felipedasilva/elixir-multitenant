defmodule MainApp.Repo.Migrations.CreateDummyProductImports do
  use Ecto.Migration

  def change do
    create table(:dummy_product_imports) do
      add :name, :string
      add :url, :string
      add :description, :string
      add :job_interval_in_seconds, :string

      timestamps(type: :utc_datetime)
    end
  end
end
