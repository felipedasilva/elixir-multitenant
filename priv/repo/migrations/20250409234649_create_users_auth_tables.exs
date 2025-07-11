defmodule MainApp.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:applications) do
      add :name, :string, null: false
      add :tenant, :string, null: false
      add :subdomain, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:applications, [:subdomain])

    create unique_index(:applications, [:tenant])

    create table(:application_users) do
      add :application_id, references(:applications, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:application_users, [:application_id, :user_id],
             name: :unique_application_user
           )
  end
end
