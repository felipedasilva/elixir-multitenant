defmodule MainApp.ExternalInventories do
  @moduledoc """
  The ExternalInventories context.
  """

  import Ecto.Query, warn: false
  alias MainApp.Repo

  alias MainApp.ExternalInventories.DummyProductImport
  alias MainApp.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any dummy_product_import changes.

  The broadcasted messages match the pattern:

    * {:created, %DummyProductImport{}}
    * {:updated, %DummyProductImport{}}
    * {:deleted, %DummyProductImport{}}

  """
  def subscribe_dummy_product_imports(%Scope{} = scope) do
    key = scope.application.id

    Phoenix.PubSub.subscribe(MainApp.PubSub, "application:#{key}:dummy_product_imports")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.application.id

    Phoenix.PubSub.broadcast(MainApp.PubSub, "application:#{key}:dummy_product_imports", message)
  end

  @doc """
  Returns the list of dummy_product_imports.

  ## Examples

      iex> list_dummy_product_imports(scope)
      [%DummyProductImport{}, ...]

  """
  @spec list_dummy_product_imports(%Scope{}, map) ::
          {:ok, {[DummyProductImport], Flop.Meta.t()}} | {:error, Flop.Meta.t()}
  def list_dummy_product_imports(%Scope{} = scope, params) do
    Flop.validate_and_run(DummyProductImport, params,
      for: DummyProductImport,
      query_opts: [prefix: scope.application.tenant]
    )
  end

  @doc """
  Gets a single dummy_product_import.

  Raises `Ecto.NoResultsError` if the Dummy product import does not exist.

  ## Examples

      iex> get_dummy_product_import!(123)
      %DummyProductImport{}

      iex> get_dummy_product_import!(456)
      ** (Ecto.NoResultsError)

  """
  def get_dummy_product_import!(%Scope{} = scope, id) do
    Repo.get!(DummyProductImport, id, prefix: scope.application.tenant)
  end

  @doc """
  Gets a single dummy_product_import.

  Returns `nil` if the Dummy product import does not exist.

  ## Examples

      iex> get_dummy_product_import(123)
      %DummyProductImport{}

      iex> get_dummy_product_import(456)
      nil

  """
  def get_dummy_product_import(%Scope{} = scope, id) do
    Repo.get(DummyProductImport, id, prefix: scope.application.tenant)
  end

  @doc """
  Creates a dummy_product_import.

  ## Examples

      iex> create_dummy_product_import(%{field: value})
      {:ok, %DummyProductImport{}}

      iex> create_dummy_product_import(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_dummy_product_import(%Scope{} = scope, attrs \\ %{}) do
    with {:ok, dummy_product_import = %DummyProductImport{}} <-
           %DummyProductImport{}
           |> DummyProductImport.changeset(attrs, scope)
           |> Repo.insert(prefix: scope.application.tenant) do
      broadcast(scope, {:created, dummy_product_import})
      {:ok, dummy_product_import}
    end
  end

  @doc """
  Updates a dummy_product_import.

  ## Examples

      iex> update_dummy_product_import(dummy_product_import, %{field: new_value})
      {:ok, %DummyProductImport{}}

      iex> update_dummy_product_import(dummy_product_import, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_dummy_product_import(
        %Scope{} = scope,
        %DummyProductImport{} = dummy_product_import,
        attrs
      ) do
    true = dummy_product_import.__meta__.prefix == scope.application.tenant

    with {:ok, dummy_product_import = %DummyProductImport{}} <-
           dummy_product_import
           |> DummyProductImport.changeset(attrs, scope)
           |> Repo.update(prefix: scope.application.tenant) do
      broadcast(scope, {:updated, dummy_product_import})
      {:ok, dummy_product_import}
    end
  end

  @doc """
  Deletes a dummy_product_import.

  ## Examples

      iex> delete_dummy_product_import(dummy_product_import)
      {:ok, %DummyProductImport{}}

      iex> delete_dummy_product_import(dummy_product_import)
      {:error, %Ecto.Changeset{}}

  """
  def delete_dummy_product_import(%Scope{} = scope, %DummyProductImport{} = dummy_product_import) do
    true = dummy_product_import.__meta__.prefix == scope.application.tenant

    with {:ok, dummy_product_import = %DummyProductImport{}} <-
           Repo.delete(dummy_product_import, prefix: scope.application.tenant) do
      broadcast(scope, {:deleted, dummy_product_import})
      {:ok, dummy_product_import}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dummy_product_import changes.

  ## Examples

      iex> change_dummy_product_import(dummy_product_import)
      %Ecto.Changeset{data: %DummyProductImport{}}

  """
  def change_dummy_product_import(
        %Scope{} = scope,
        %DummyProductImport{} = dummy_product_import,
        attrs \\ %{}
      ) do
    DummyProductImport.changeset(dummy_product_import, attrs, scope)
  end
end
