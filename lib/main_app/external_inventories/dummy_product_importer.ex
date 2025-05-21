defmodule MainApp.ExternalInventories.DummyProductImporter do
  alias MainApp.ExternalInventories.DummyProductWorker
  alias MainApp.ExternalInventories.DummyProductImport

  def import_products(scope, %DummyProductImport{} = dummy_product_import) do
    # true = scope.application.id == dummy_product_import.__meta__.prefix

    url = dummy_product_import.url
    {:ok, dummy_products} = fetch_dummy_products(url, scope)

    dummy_products
    |> Enum.map(fn dummy_product ->
      DummyProductWorker.new(%{
        "application" => scope.application,
        "dummy_product" => dummy_product
      })
      |> Oban.insert!()
    end)
  end

  defp fetch_dummy_products(url, scope, products \\ [], skip \\ 0) do
    case fetch_page(url, skip) do
      {:ok, %{"products" => products_from_api, "total" => total, "limit" => limit}} ->
        new_products = products ++ products_from_api

        if length(new_products) >= total do
          {:ok, new_products}
        else
          Process.sleep(500)
          fetch_dummy_products(url, scope, new_products, skip + limit)
        end

      {:error, reason} ->
        {:error, "Failed to fetch products: #{inspect(reason)}"}
    end
  end

  defp fetch_page(url, skip) do
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
        fetch_page(url, skip)

      {:ok, response} ->
        {:error, "Unexpected response: #{inspect(response)}"}

      {:error, error} ->
        {:error, error}
    end
  end
end
