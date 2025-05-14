defmodule MainApp.Workers.TenantMigrationWorker do
  alias MainApp.Tenants
  use Oban.Worker, queue: :migration

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"application" => %{"tenant" => tenant}}}) do
    IO.inspect(tenant, label: "run migrations to tenant")
    Tenants.run_tenant_migrations_to_tenant(tenant)

    :ok
  end
end
