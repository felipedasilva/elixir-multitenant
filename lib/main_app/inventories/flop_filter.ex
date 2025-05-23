defmodule MainApp.Inventories.FlopFilter do
  import Ecto.Query

  def search_products_filter(query, %Flop.Filter{value: value}, _opts) do
    if is_nil(value) or value == "" do
      query
    else
      pattern = "%#{value}%"

      query
      |> where(
        [u],
        ilike(u.sku, ^pattern) or
          ilike(u.name, ^pattern) or
          ilike(u.description, ^pattern)
      )
    end
  end
end
