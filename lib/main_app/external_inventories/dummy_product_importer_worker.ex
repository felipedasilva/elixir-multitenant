defmodule MainApp.ExternalInventories.DummyProductImporterWorker do
  alias MainApp.ExternalInventories
  alias MainApp.Accounts.Scope
  alias MainApp.ExternalInventories.DummyProductImporter
  alias MainApp.ExternalInventories.DummyProductImport
  alias MainApp.Repo
  alias MainApp.Accounts.Application
  use Oban.Worker, queue: :external_dummy_product_importer

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "application_id" => application_id,
          "dummy_product_import_id" => dummy_product_import_id
        }
      }) do
    with %Application{} = application <- Repo.get(Application, application_id),
         %DummyProductImport{} = dummy_product_import <-
           ExternalInventories.get_dummy_product_import(
             Scope.put_application(%Scope{}, application),
             dummy_product_import_id
           ) do
      case import_dummy_products(application, dummy_product_import) do
        :ok ->
          schedule_next_job(application, dummy_product_import)
          :ok

        {:error, error} ->
          {:error, error}
      end
    else
      nil -> :ok
    end
  end

  def import_dummy_products(
        %Application{} = application,
        %DummyProductImport{} = dummy_product_import
      ) do
    scope = Scope.put_application(%Scope{}, application)

    DummyProductImporter.import_dummy_products(scope, dummy_product_import)
  end

  def schedule_next_job(
        %Application{} = application,
        %DummyProductImport{} = dummy_product_import
      ) do
    __MODULE__.new(
      %{
        application_id: application.id,
        dummy_product_import_id: dummy_product_import.id
      },
      schedule_in: 3600
    )
    |> Oban.insert!()
  end
end
