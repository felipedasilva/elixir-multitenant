defmodule MainApp.ExternalInventories.DummyProductImporterWorkerTest do
  alias MainApp.ExternalInventories.DummyProductWorker
  alias MainApp.ExternalInventories.DummyProductFetchAPI
  alias MainApp.Accounts.Scope
  alias MainApp.ExternalInventories.DummyProductImporterWorker
  use MainApp.DataCase, async: true
  use Mimic

  import MainApp.InventoriesFixtures
  import MainApp.ExternalInventoriesFixtures

  @product_api_1 %{
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

  @product_api_2 %{
    "id" => 2,
    "title" => "Eyeshadow Palette with Mirror",
    "description" =>
      "The Eyeshadow Palette with Mirror offers a versatile range of eyeshadow shades for creating stunning eye looks. With a built-in mirror, it's convenient for on-the-go makeup application.",
    "category" => "beauty",
    "price" => 19.99,
    "discountPercentage" => 18.19,
    "rating" => 2.86,
    "stock" => 34,
    "tags" => ["beauty", "eyeshadow"],
    "brand" => "Glamour Beauty",
    "sku" => "BEA-GLA-EYE-002",
    "weight" => 9,
    "dimensions" => %{
      "width" => 9.26,
      "height" => 22.47,
      "depth" => 27.67
    },
    "warrantyInformation" => "1 year warranty",
    "shippingInformation" => "Ships in 2 weeks",
    "availabilityStatus" => "In Stock",
    "reviews" => [
      %{
        "rating" => 5,
        "comment" => "Great product!",
        "date" => "2025-04-30T09:41:02.053Z",
        "reviewerName" => "Savannah Gomez",
        "reviewerEmail" => "savannah.gomez@x.dummyjson.com"
      },
      %{
        "rating" => 4,
        "comment" => "Awesome product!",
        "date" => "2025-04-30T09:41:02.053Z",
        "reviewerName" => "Christian Perez",
        "reviewerEmail" => "christian.perez@x.dummyjson.com"
      },
      %{
        "rating" => 1,
        "comment" => "Poor quality!",
        "date" => "2025-04-30T09:41:02.053Z",
        "reviewerName" => "Nicholas Bailey",
        "reviewerEmail" => "nicholas.bailey@x.dummyjson.com"
      }
    ],
    "returnPolicy" => "7 days return policy",
    "minimumOrderQuantity" => 20,
    "meta" => %{
      "createdAt" => "2025-04-30T09:41:02.053Z",
      "updatedAt" => "2025-04-30T09:41:02.053Z",
      "barcode" => "9170275171413",
      "qrCode" => "https://cdn.dummyjson.com/public/qr-code.png"
    },
    "images" => [
      "https://cdn.dummyjson.com/product-images/beauty/eyeshadow-palette-with-mirror/1.webp"
    ],
    "thumbnail" =>
      "https://cdn.dummyjson.com/product-images/beauty/eyeshadow-palette-with-mirror/thumbnail.webp"
  }

  describe "DummyProductImporterWorker.perform/1" do
    test "should create jobs for each product from dummy api" do
      application = get_default_application!()
      scope = %Scope{} |> Scope.put_application(application)
      dummy_product_import = dummy_product_import_fixture(scope)

      DummyProductFetchAPI
      |> stub(:fetch_products, fn _x, _y -> :stub end)
      |> expect(:fetch_products, fn url, skip ->
        assert url == dummy_product_import.url
        assert 0 == skip

        {:ok, %{"products" => [@product_api_1, @product_api_2], "limit" => 10}}
      end)
      |> expect(:fetch_products, fn url, skip ->
        assert url == dummy_product_import.url
        assert 10 == skip

        {:ok, %{"products" => [], "limit" => 10}}
      end)

      job = Oban.Testing.build_job(DummyProductImporterWorker, %{}, priority: 1)
      DummyProductImporterWorker.perform(job)

      all_enqueued_jobs = all_enqueued(worker: DummyProductWorker)

      application_id = application.id
      application_name = application.name
      application_tenant = application.tenant

      assert Enum.any?(all_enqueued_jobs, fn
               %{
                 queue: "external_dummy_product",
                 args: %{
                   "application" => %{
                     "id" => ^application_id,
                     "name" => ^application_name,
                     "tenant" => ^application_tenant
                   },
                   "dummy_product" => @product_api_2
                 }
               } ->
                 true

               _ ->
                 false
             end)

      assert Enum.any?(all_enqueued_jobs, fn
               %{
                 queue: "external_dummy_product",
                 args: %{
                   "application" => %{
                     "id" => ^application_id,
                     "name" => ^application_name,
                     "tenant" => ^application_tenant
                   },
                   "dummy_product" => @product_api_1
                 }
               } ->
                 true

               _ ->
                 false
             end)
    end
  end

  test "should create jobs for each application with dummy products" do
    application = get_default_application!()
    second_application = get_second_application!()
    scope = %Scope{} |> Scope.put_application(application)
    second_scope = %Scope{} |> Scope.put_application(second_application)
    dummy_product_import = dummy_product_import_fixture(scope)
    second_dummy_product_import = dummy_product_import_fixture(second_scope)

    DummyProductFetchAPI
    |> stub(:fetch_products, fn _x, _y -> :stub end)
    |> expect(:fetch_products, fn url, skip ->
      assert url == dummy_product_import.url
      assert 0 == skip

      {:ok, %{"products" => [@product_api_1], "limit" => 10}}
    end)
    |> expect(:fetch_products, fn url, skip ->
      assert url == dummy_product_import.url
      assert 10 == skip

      {:ok, %{"products" => [], "limit" => 10}}
    end)
    |> expect(:fetch_products, fn url, skip ->
      assert url == second_dummy_product_import.url
      assert 0 == skip

      {:ok, %{"products" => [@product_api_2], "limit" => 10}}
    end)
    |> expect(:fetch_products, fn url, skip ->
      assert url == second_dummy_product_import.url
      assert 10 == skip

      {:ok, %{"products" => [], "limit" => 10}}
    end)

    job = Oban.Testing.build_job(DummyProductImporterWorker, %{}, priority: 1)
    DummyProductImporterWorker.perform(job)

    all_enqueued_jobs = all_enqueued(worker: DummyProductWorker)

    application_id = application.id
    application_name = application.name
    application_tenant = application.tenant

    second_application_id = second_application.id
    second_application_name = second_application.name
    second_application_tenant = second_application.tenant

    assert Enum.any?(all_enqueued_jobs, fn
             %{
               queue: "external_dummy_product",
               args: %{
                 "application" => %{
                   "id" => ^application_id,
                   "name" => ^application_name,
                   "tenant" => ^application_tenant
                 },
                 "dummy_product" => @product_api_1
               }
             } ->
               true

             _ ->
               false
           end)

    assert Enum.any?(all_enqueued_jobs, fn
             %{
               queue: "external_dummy_product",
               args: %{
                 "application" => %{
                   "id" => ^second_application_id,
                   "name" => ^second_application_name,
                   "tenant" => ^second_application_tenant
                 },
                 "dummy_product" => @product_api_2
               }
             } ->
               true

             _ ->
               false
           end)
  end
end
