defmodule MainApp.InventoriesTest do
  alias MainApp.Accounts.Scope
  use MainApp.DataCase, async: true

  alias MainApp.Inventories
  alias MainApp.Accounts.Application

  import MainApp.InventoriesFixtures

  setup do
    default_application = MainApp.Repo.get_by!(Application, %{name: "myapp1"})
    second_application = MainApp.Repo.get_by!(Application, %{name: "myapp2"})

    default_scope = Scope.put_application(%Scope{}, default_application)
    second_scope = Scope.put_application(%Scope{}, second_application)

    {:ok, default_scope: default_scope, second_scope: second_scope}
  end

  describe "create_product/2" do
    test "requires sku to be set", %{default_scope: default_scope} do
      {:error, changeset} = Inventories.create_product(default_scope, %{name: "product1"})

      assert %{sku: ["can't be blank"]} == errors_on(changeset)
    end

    test "requires name to be set", %{default_scope: default_scope} do
      {:error, changeset} = Inventories.create_product(default_scope, %{sku: "sku1"})

      assert %{name: ["can't be blank"]} == errors_on(changeset)
    end

    test "create product", %{default_scope: default_scope} do
      {:ok, product} =
        Inventories.create_product(default_scope, %{
          sku: "sku1",
          name: "product1",
          description: "product description"
        })

      refute is_nil(product.id)
      assert "sku1" == product.sku
      assert "product1" == product.name
      assert "product description" == product.description
    end
  end

  describe "get_product_by_id/2" do
    test "does not return product from another tenant", %{
      default_scope: default_scope,
      second_scope: second_scope
    } do
      {:ok, product} = create_product(second_scope)

      product = Inventories.get_product_by_id(default_scope, product.id)

      assert is_nil(product)
    end

    test "return product", %{default_scope: default_scope} do
      {:ok, product} = create_product(default_scope)

      found_product = Inventories.get_product_by_id(default_scope, product.id)

      refute is_nil(product)
      assert product == found_product
    end
  end

  describe "update_product/2" do
    test "does not allow updating a product from another tenant", %{
      default_scope: default_scope,
      second_scope: second_scope
    } do
      {:ok, product} = create_product(second_scope)

      assert_raise Ecto.StaleEntryError, fn ->
        Inventories.update_product(default_scope, product, %{
          sku: "test"
        })
      end
    end

    test "allow to update a product", %{default_scope: default_scope} do
      {:ok, product} = create_product(default_scope)

      Inventories.update_product(default_scope, product, %{sku: "skuupdated"})

      assert "skuupdated" == Inventories.get_product_by_id(default_scope, product.id).sku
    end
  end

  describe "delete_product/2" do
    test "does not allow deleting a product from another tenant", %{
      default_scope: default_scope,
      second_scope: second_scope
    } do
      {:ok, product} = create_product(second_scope)

      assert_raise Ecto.StaleEntryError, fn ->
        Inventories.delete_product(default_scope, product)
      end
    end

    test "allow to delete a product", %{default_scope: default_scope} do
      {:ok, product} = create_product(default_scope)

      Inventories.delete_product(default_scope, product)

      assert is_nil(Inventories.get_product_by_id(default_scope, product.id))
    end
  end

  describe "list_products/2" do
    test "does not allow to listing a product from another tenant", %{
      default_scope: default_scope,
      second_scope: second_scope
    } do
      create_product(second_scope)

      {:ok, {products, _}} = Inventories.list_products(default_scope, %{})

      assert [] == products
    end

    test "allow to list a product from another tenant", %{default_scope: default_scope} do
      {:ok, product} = create_product(default_scope)

      {:ok, {products, _}} = Inventories.list_products(default_scope, %{})

      assert [product] == products
    end
  end
end
