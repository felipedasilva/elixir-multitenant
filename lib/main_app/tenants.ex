defmodule MainApp.Tenants do
  @moduledoc false

  require Logger
  alias MainApp.Repo

  @migrations_folder "priv/repo/migrations_tenant"

  @doc """
  Fetch all applications and run migrations for each
  """
  def run_tenant_migration_applications() do
    Logger.info("Run tenant migrations for all applications")

    applications = MainApp.Accounts.list_applications()

    tenants =
      applications
      |> Enum.map(fn application -> application.tenant end)

    Logger.info(
      "Tenants found that will have tenant migrations executed: #{Enum.join(tenants, ", ")}"
    )

    MainApp.Tenants.run_tenant_migration_to_tenants(tenants)
  end

  def run_tenant_migration_to_tenants(tenants) do
    Enum.each(tenants, &run_tenant_migrations_to_tenant/1)
  end

  def run_tenant_migrations_to_tenant(tenant) do
    Logger.info("Running tenant migration for the tenant #{tenant}")

    Logger.info("Creating tenant #{tenant} if not exists")
    Repo.query!("CREATE SCHEMA IF NOT EXISTS \"#{tenant}\"")

    path = Application.app_dir(:app, @migrations_folder)
    opts = Keyword.put_new([], :prefix, tenant) |> Keyword.put(:all, true)
    Ecto.Migrator.run(App.Repo, path, :up, opts)

    Logger.info("Tenant migration completed for the tenant #{tenant}")
  end

  @doc """
  Only tenants that contain "tenant_" can be dropped
  """
  def drop_tenant(tenant) do
    case String.contains?(tenant, "tenant_") do
      true ->
        Logger.info("Dropping tenant #{tenant}")
        Repo.query!("DROP SCHEMA IF EXISTS \"#{tenant}\" CASCADE")
        Logger.info("Dropped tenant #{tenant}")

      false ->
        Logger.info("Invalid tenant provided #{tenant}")
    end
  end
end
