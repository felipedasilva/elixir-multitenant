defmodule MainApp.ExternalInventories.DummyProductWorkerTest do
  use MainApp.DataCase, async: true

  alias MainApp.ExternalInventories.DummyProductWorker
  import MainApp.InventoriesFixtures

  defp get_default_event() do
    application = get_default_application!()

    %{
      "application" => %{
        "id" => application.id,
        "name" => application.name,
        "tenant" => application.tenant
      },
      "dummy_product" => %{
        "id" => 3,
        "sku" => "BEA-VEL-POW-003",
        "meta" => %{
          "qrCode" => "https://cdn.dummyjson.com/public/qr-code.png",
          "barcode" => "8418883906837",
          "createdAt" => "2025-04-30T09:41:02.053Z",
          "updatedAt" => "2025-04-30T09:41:02.053Z"
        },
        "tags" => ["beauty", "face powder"],
        "brand" => "Velvet Touch",
        "price" => 14.99,
        "stock" => 89,
        "title" => "Powder Canister",
        "images" => [
          "https://cdn.dummyjson.com/product-images/beauty/powder-canister/1.webp"
        ],
        "rating" => 4.64,
        "weight" => 8,
        "reviews" => [
          %{
            "date" => "2025-04-30T09:41:02.053Z",
            "rating" => 4,
            "comment" => "Would buy again!",
            "reviewerName" => "Alexander Jones",
            "reviewerEmail" => "alexander.jones@x.dummyjson.com"
          },
          %{
            "date" => "2025-04-30T09:41:02.053Z",
            "rating" => 5,
            "comment" => "Highly impressed!",
            "reviewerName" => "Elijah Cruz",
            "reviewerEmail" => "elijah.cruz@x.dummyjson.com"
          },
          %{
            "date" => "2025-04-30T09:41:02.053Z",
            "rating" => 1,
            "comment" => "Very dissatisfied!",
            "reviewerName" => "Avery Perez",
            "reviewerEmail" => "avery.perez@x.dummyjson.com"
          }
        ],
        "category" => "beauty",
        "thumbnail" =>
          "https://cdn.dummyjson.com/product-images/beauty/powder-canister/thumbnail.webp",
        "dimensions" => %{
          "depth" => 20.59,
          "width" => 29.27,
          "height" => 27.93
        },
        "description" =>
          "The Powder Canister is a finely milled setting powder designed to set makeup and control shine. With a lightweight and translucent formula, it provides a smooth and matte finish.",
        "returnPolicy" => "No return policy",
        "availabilityStatus" => "In Stock",
        "discountPercentage" => 9.84,
        "shippingInformation" => "Ships in 1-2 business days",
        "warrantyInformation" => "3 months warranty",
        "minimumOrderQuantity" => 22
      }
    }
  end

  describe "DummyProductWorker.perform/1" do
    test "should raise an error when application not found" do
      job =
        Oban.Testing.build_job(
          DummyProductWorker,
          %{
            application: %{"id" => 100, "name" => "notfound", "tenant" => "notfound"},
            dummy_product: %{}
          },
          priority: 1
        )

      assert_raise Ecto.NoResultsError, fn ->
        DummyProductWorker.perform(job)
      end
    end

    test "should raise an error when dummy product has invalid attributes" do
      application = get_default_application!()

      job =
        Oban.Testing.build_job(
          DummyProductWorker,
          %{
            application: %{
              "id" => application.id,
              "name" => application.name,
              "tenant" => application.tenant
            },
            dummy_product: %{}
          },
          priority: 1
        )

      assert {:error,
              [
                {"Required properties id, sku, price, title, description were not present.", "#"}
              ]} == DummyProductWorker.perform(job)
    end

    test "should create a new product when dummy product has valid attributes" do
      job =
        Oban.Testing.build_job(
          DummyProductWorker,
          get_default_event(),
          priority: 1
        )

      {:ok, product} = DummyProductWorker.perform(job)

      refute is_nil(product.id)
      assert "BEA-VEL-POW-003" == product.sku
      assert "Powder Canister" == product.name
      assert "dummy_product" == product.source
      assert "3" == product.external_id

      assert "The Powder Canister is a finely milled setting powder designed to set makeup and control shine. With a lightweight and translucent formula, it provides a smooth and matte finish." ==
               product.description
    end

    test "should update a product that already exists" do
      job =
        Oban.Testing.build_job(
          DummyProductWorker,
          get_default_event(),
          priority: 1
        )

      {:ok, product} = DummyProductWorker.perform(job)

      {:ok, product_updated} = DummyProductWorker.perform(job)

      assert product.id == product_updated.id
      assert product.sku == product_updated.sku
      assert product.name == product_updated.name
      assert product.description == product_updated.description
      assert product.external_id == product_updated.external_id
      assert "dummy_product" == product_updated.source
    end
  end
end
