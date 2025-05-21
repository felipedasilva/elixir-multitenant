defmodule MainApp.ExternalInventories.DummyProductWorker do
  alias MainApp.Accounts.Scope
  alias MainApp.Inventories
  alias MainApp.Accounts
  alias MainApp.Accounts.Application
  use Oban.Worker, queue: :external_dummy_product

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"application" => %{"id" => id}, "dummy_product" => dummy_product}
      }) do
    application = Accounts.get_application_by_id!(id)

    import_dummy_product(application, dummy_product)
  end

  def import_dummy_product(%Application{} = application, dummy_product) do
    case validate_dummy_product_data(dummy_product) do
      :ok ->
        scope = Scope.put_application(%Scope{}, application)

        case Inventories.get_product_by_slug(scope, dummy_product["sku"]) do
          nil ->
            Inventories.create_product(scope, %{
              "name" => dummy_product["title"],
              "slug" => dummy_product["sku"],
              "description" => dummy_product["description"]
            })

          product ->
            Inventories.update_product(scope, product, %{
              "name" => dummy_product["title"],
              "slug" => dummy_product["sku"],
              "description" => dummy_product["description"]
            })
        end

      {:error, errors} ->
        {:error, errors}
    end
  end

  def validate_dummy_product_data(dummy_product) do
    review_schema = %{
      "type" => "object",
      "required" => ["date", "rating", "comment", "reviewerName", "reviewerEmail"],
      "properties" => %{
        "date" => %{"type" => "string", "format" => "date-time"},
        "rating" => %{"type" => "integer", "minimum" => 1, "maximum" => 5},
        "comment" => %{"type" => "string"},
        "reviewerName" => %{"type" => "string"},
        "reviewerEmail" => %{"type" => "string", "format" => "email"}
      }
    }

    dimensions_schema = %{
      "type" => "object",
      "required" => ["depth", "width", "height"],
      "properties" => %{
        "depth" => %{"type" => "number", "minimum" => 0},
        "width" => %{"type" => "number", "minimum" => 0},
        "height" => %{"type" => "number", "minimum" => 0}
      }
    }

    meta_schema = %{
      "type" => "object",
      "properties" => %{
        "qrCode" => %{"type" => "string", "format" => "uri"},
        "barcode" => %{"type" => "string"},
        "createdAt" => %{"type" => "string", "format" => "date-time"},
        "updatedAt" => %{"type" => "string", "format" => "date-time"}
      }
    }

    product_schema = %{
      "type" => "object",
      "required" => ["id", "sku", "brand", "price", "stock", "title", "category", "description"],
      "properties" => %{
        "id" => %{"type" => "integer", "minimum" => 1},
        "sku" => %{"type" => "string"},
        "meta" => meta_schema,
        "tags" => %{
          "type" => "array",
          "items" => %{"type" => "string"}
        },
        "brand" => %{"type" => "string"},
        "price" => %{"type" => "number", "minimum" => 0},
        "stock" => %{"type" => "integer", "minimum" => 0},
        "title" => %{"type" => "string"},
        "images" => %{
          "type" => "array",
          "items" => %{"type" => "string", "format" => "uri"}
        },
        "rating" => %{"type" => "number", "minimum" => 0, "maximum" => 5},
        "weight" => %{"type" => "number", "minimum" => 0},
        "reviews" => %{
          "type" => "array",
          "items" => review_schema
        },
        "category" => %{"type" => "string"},
        "thumbnail" => %{"type" => "string", "format" => "uri"},
        "dimensions" => dimensions_schema,
        "description" => %{"type" => "string"},
        "returnPolicy" => %{"type" => "string"},
        "availabilityStatus" => %{"type" => "string"},
        "discountPercentage" => %{"type" => "number", "minimum" => 0, "maximum" => 100},
        "shippingInformation" => %{"type" => "string"},
        "warrantyInformation" => %{"type" => "string"},
        "minimumOrderQuantity" => %{"type" => "integer", "minimum" => 0}
      }
    }

    schema = ExJsonSchema.Schema.resolve(product_schema)

    ExJsonSchema.Validator.validate(schema, dummy_product)
  end
end
