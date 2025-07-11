defmodule MainApp.Inventories do
  @moduledoc """
  The Inventories context.
  """

  import Ecto.Query, warn: false
  alias MainApp.Accounts.Scope
  alias MainApp.Repo

  alias MainApp.Inventories.{Product}

  def subscribe_products(%Scope{application: application}) do
    key = application.id

    Phoenix.PubSub.subscribe(MainApp.PubSub, "application:#{key}:products")
  end

  def broadcast_product(%Scope{application: application}, message) do
    key = application.id

    Phoenix.PubSub.broadcast(MainApp.PubSub, "application:#{key}:products", message)
  end

  def create_product(%Scope{application: %{tenant: tenant}} = scope, attrs \\ %{}) do
    with {:ok, %{model: product = %Product{}}} <-
           %Product{}
           |> PaperTrail.add_prefix(tenant)
           |> Product.changeset(attrs)
           |> PaperTrail.insert(prefix: tenant) do
      broadcast_product(scope, {:created, product})
      {:ok, product}
    end
  end

  def get_product!(%Scope{application: %{tenant: tenant}}, id) do
    Repo.get!(Product, id, prefix: tenant)
  end

  def get_product_by_id(%Scope{application: %{tenant: tenant}}, id) do
    Repo.get(Product, id, prefix: tenant)
  end

  def get_product_by_sku(%Scope{application: %{tenant: tenant}}, sku) do
    Repo.get_by(Product, [sku: sku], prefix: tenant)
  end

  def get_product_changes_by_id(%Scope{application: %{tenant: tenant}}, id) do
    PaperTrail.get_versions(Product, id, prefix: tenant)
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

  def update_product(%Scope{application: %{tenant: tenant}} = scope, product, attrs \\ %{}) do
    true = product.__meta__.prefix == tenant

    changeset = change_product(%Scope{application: %{tenant: tenant}}, product, attrs)

    cond do
      not changeset.valid? ->
        {:error, changeset}

      changeset.changes == %{} ->
        {:ok, product}

      true ->
        with {:ok, %{model: product = %Product{}}} <-
               PaperTrail.update(changeset, prefix: tenant) do
          broadcast_product(scope, {:updated, product})
          {:ok, product}
        end
    end
  end

  def delete_product(%Scope{application: %{tenant: tenant}} = scope, %Product{} = product) do
    true = product.__meta__.prefix == tenant

    with {:ok, %{model: product = %Product{}}} <-
           PaperTrail.delete(product, prefix: tenant) do
      broadcast_product(scope, {:deleted, product})
      {:ok, product}
    end
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
            %{field: :sku, op: :ilike_or, value: search},
            %{field: :name, op: :ilike_or, value: search},
            %{field: :description, op: :ilike_or, value: search}
          ])
      end

    Flop.validate_and_run(Product, params, for: Product, query_opts: [prefix: tenant])
  end
end
