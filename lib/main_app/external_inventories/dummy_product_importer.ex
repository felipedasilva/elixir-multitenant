defmodule MainApp.ExternalInventories.DummyProductImporter do
  alias MainApp.Accounts.Scope
  alias MainApp.ExternalInventories.DummyProductWorker
  alias MainApp.ExternalInventories.DummyProductImport
  alias MainApp.ExternalInventories.DummyProductFetchAPI

  def import_dummy_products(scope, %DummyProductImport{} = dummy_product_import) do
    true = scope.application.tenant == dummy_product_import.__meta__.prefix

    url = dummy_product_import.url

    fetch_dummy_products(scope, url, 0)
  end

  defp import_dummy_product(%Scope{} = scope, dummy_product) do
    DummyProductWorker.new(%{
      "application" => scope.application,
      "dummy_product" => dummy_product
    })
    |> Oban.insert!()
  end

  defp fetch_dummy_products(scope, url, skip) do
    case DummyProductFetchAPI.fetch_products(url, skip) do
      {:ok, %{"products" => products_from_api, "limit" => limit}} ->
        Enum.each(products_from_api, fn dummy_product ->
          import_dummy_product(scope, dummy_product)
        end)

        if length(products_from_api) == 0 do
          :ok
        else
          Process.sleep(500)
          fetch_dummy_products(scope, url, skip + limit)
        end

      {:error, reason} ->
        {:error, "Failed to fetch products: #{inspect(reason)}"}
    end
  end
end

defmodule MainApp.ExternalInventories.DummyProductFetchAPI do
  def fetch_products(url, skip) do
    query_params = %{skip: skip, limit: 30}

    case HTTPoison.get("#{url}?#{URI.encode_query(query_params)}", [
           {"Accept", "application/json"},
           {"Content-Type", "application/json"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: 429}} ->
        # Handle rate limiting by waiting and retrying
        Process.sleep(2000)
        fetch_products(url, skip)

      {:ok, response} ->
        {:error, "Unexpected response: #{inspect(response)}"}

      {:error, error} ->
        {:error, error}
    end
  end
end
