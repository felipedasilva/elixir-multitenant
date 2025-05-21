defmodule MainApp.Inventories do
  @moduledoc """
  The Inventories context.
  """

  import Ecto.Query, warn: false
  alias MainApp.Accounts.Scope
  alias MainApp.Repo

  alias MainApp.Inventories.{Product}

  def create_product(%Scope{application: %{tenant: tenant}}, attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  def get_product!(%Scope{application: %{tenant: tenant}}, id) do
    Repo.get!(Product, id, prefix: tenant)
  end

  def get_product_by_id(%Scope{application: %{tenant: tenant}}, id) do
    Repo.get(Product, id, prefix: tenant)
  end

  def get_product_by_slug(%Scope{application: %{tenant: tenant}}, slug) do
    Repo.get_by(Product, [slug: slug], prefix: tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the product.

  ## Examples

      iex> change_product(%Scope{application: %{tenant: tenant}}, product, attrs)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(_, product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  def update_product(%Scope{application: %{tenant: tenant}}, product, attrs \\ %{}) do
    change_product(%Scope{application: %{tenant: tenant}}, product, attrs)
    |> Repo.update(prefix: tenant)
  end

  def delete_product(%Scope{application: %{tenant: tenant}}, %Product{} = product) do
    Repo.delete(product, prefix: tenant)
  end

  @spec list_products(String, map) ::
          {:ok, {[Product], Flop.Meta.t()}} | {:error, Flop.Meta.t()}
  def list_products(%Scope{application: %{tenant: tenant}}, params \\ %{}) do
    params =
      case Map.get(params, "search") do
        "" ->
          params

        nil ->
          params

        search ->
          params
          |> Map.put("filters", [
            %{field: :slug, op: :ilike_or, value: search},
            %{field: :name, op: :ilike_or, value: search},
            %{field: :description, op: :ilike_or, value: search}
          ])
      end

    Flop.validate_and_run(Product, params, for: Product, query_opts: [prefix: tenant])
  end
end
