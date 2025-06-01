defmodule MainApp.ExternalInventories.DummyProductImporterWorker do
  alias MainApp.Accounts.Scope
  alias MainApp.ExternalInventories.DummyProductImporter
  alias MainApp.ExternalInventories.DummyProductImport
  alias MainApp.Repo
  alias MainApp.Accounts.Application
  use Oban.Worker, queue: :external_dummy_product_importer

  @impl Oban.Worker
  def perform(%Oban.Job{} = _args) do
    applications = Repo.all(Application)

    applications
    |> Enum.each(fn application ->
      dummy_product_imports = Repo.all(DummyProductImport, prefix: application.tenant)

      dummy_product_imports
      |> Enum.each(fn dummy_product_import ->
        DummyProductImporter.import_dummy_products(
          Scope.put_application(%Scope{}, application),
          dummy_product_import
        )

        :ok
      end)
    end)

    :ok
  end
end
