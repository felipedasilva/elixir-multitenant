defmodule MainApp.Workers.TenantMigrationWorker do
  alias MainApp.Tenants
  use Oban.Worker, queue: :migration

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"application" => application}}) do
    IO.inspect(application, label: "application")
    Tenants.run_tenant_migrations_to_tenant(application.tenant)

    :ok
  end
end
