defmodule MainApp.InventoriesTest do
  use MainApp.DataCase, async: true

  alias MainApp.Inventories
  alias MainApp.Accounts.Application

  import MainApp.InventoriesFixtures

  setup do
    application_default = MainApp.Repo.get_by!(Application, %{name: "myapp1"})
    application_second = MainApp.Repo.get_by!(Application, %{name: "myapp2"})

    {:ok, default_tenant: application_default.tenant, second_tenant: application_second.tenant}
  end

  describe "create_product/2" do
    test "requires slug to be set", %{default_tenant: default_tenant} do
      {:error, changeset} = Inventories.create_product(default_tenant, %{name: "product1"})

      assert %{slug: ["can't be blank"]} == errors_on(changeset)
    end

    test "requires name to be set", %{default_tenant: default_tenant} do
      {:error, changeset} = Inventories.create_product(default_tenant, %{slug: "slug1"})

      assert %{name: ["can't be blank"]} == errors_on(changeset)
    end

    test "create product", %{default_tenant: default_tenant} do
      {:ok, product} =
        Inventories.create_product(default_tenant, %{
          slug: "slug1",
          name: "product1",
          description: "product description"
        })

      refute is_nil(product.id)
      assert "slug1" == product.slug
      assert "product1" == product.name
      assert "product description" == product.description
    end
  end

  describe "get_product_by_id/2" do
    test "does not return product from another tenant", %{
      default_tenant: default_tenant,
      second_tenant: second_tenant
    } do
      {:ok, product} = create_product(second_tenant)

      product = Inventories.get_product_by_id(default_tenant, product.id)

      assert is_nil(product)
    end

    test "return product", %{
      default_tenant: default_tenant
    } do
      {:ok, product} = create_product(default_tenant)

      found_product = Inventories.get_product_by_id(default_tenant, product.id)

      refute is_nil(product)
      assert product == found_product
    end
  end

  describe "update_product/2" do
    test "does not allow updating a product from another tenant", %{
      default_tenant: default_tenant,
      second_tenant: second_tenant
    } do
      {:ok, product} = create_product(second_tenant)

      assert_raise Ecto.StaleEntryError, fn ->
        Inventories.update_product(default_tenant, product, %{
          slug: "test"
        })
      end
    end

    test "allow to update a product", %{
      default_tenant: default_tenant
    } do
      {:ok, product} = create_product(default_tenant)

      Inventories.update_product(default_tenant, product, %{slug: "slugupdated"})

      assert "slugupdated" == Inventories.get_product_by_id(default_tenant, product.id).slug
    end
  end

  describe "delete_product/2" do
    test "does not allow deleting a product from another tenant", %{
      default_tenant: default_tenant,
      second_tenant: second_tenant
    } do
      {:ok, product} = create_product(second_tenant)

      assert_raise Ecto.StaleEntryError, fn ->
        Inventories.delete_product(default_tenant, product)
      end
    end

    test "allow to delete a product", %{
      default_tenant: default_tenant
    } do
      {:ok, product} = create_product(default_tenant)

      Inventories.delete_product(default_tenant, product)

      assert is_nil(Inventories.get_product_by_id(default_tenant, product.id))
    end
  end
end
