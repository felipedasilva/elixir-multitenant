defmodule MainApp.Repo.Migrations.CreateProductsTables do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :slug, :string
      add :name, :string
      add :description, :string, null: true

      timestamps(type: :utc_datetime)
    end
  end
end
