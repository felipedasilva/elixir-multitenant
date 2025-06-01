defmodule MainApp.InventoriesFixtures do
  @moduledoc """
  this module defines test helpers for creating
  entities via the `MainApp.Inventories` context.
  """

  alias MainApp.Accounts.Application
  alias MainApp.Inventories

  @default_product_attrs %{sku: "sku", name: "my product", description: "desc"}

  def get_default_application!() do
    MainApp.Repo.get_by!(Application, %{name: "myapp1"})
  end

  def get_second_application!() do
    MainApp.Repo.get_by!(Application, %{name: "myapp2"})
  end

  def get_default_tenant!() do
    MainApp.Repo.get_by!(Application, %{name: "myapp1"}).tenant
  end

  def get_second_tenant!() do
    MainApp.Repo.get_by!(Application, %{name: "myapp2"}).tenant
  end

  def create_product() do
    tenant = get_default_tenant!()
    create_product(tenant)
  end

  def create_product(scope, attrs \\ %{}) do
    Inventories.create_product(scope, Map.merge(@default_product_attrs, attrs))
  end
end
