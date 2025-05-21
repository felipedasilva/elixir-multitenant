defmodule MainApp.ExternalInventories.DummyProductImporterWorker do
  alias MainApp.Accounts.Scope
  alias MainApp.ExternalInventories.DummyProductImporter
  alias MainApp.ExternalInventories.DummyProductImport
  alias MainApp.Repo
  alias MainApp.Accounts.Application
  use Oban.Worker, queue: :external_dummy_product_importer

  @impl Oban.Worker
  def perform(_args) do
    IO.inspect("MainApp.Workers.DummyProductImporterWorker")

    applications = Repo.all(Application)

    applications
    |> Enum.each(fn application ->
      IO.inspect(application.tenant, label: "test")

      dummy_product_imports = Repo.all(DummyProductImport, prefix: application.tenant)

      IO.inspect(dummy_product_imports, label: "LIST")

      dummy_product_imports
      |> Enum.each(fn dummy_product_import ->
        DummyProductImporter.import_products(
          Scope.put_application(%Scope{}, application),
          dummy_product_import
        )

        IO.inspect(dummy_product_import, label: "LISTITEM")

        :ok
      end)
    end)

    :ok
  end
end
