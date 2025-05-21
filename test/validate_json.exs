defmodule JsonValidator do
  @doc """
  Validates a product JSON against a predefined schema using ex_json_schema.
  """
  def validate_product_json(json_string) do
    # Parse JSON string to Elixir map
    {:ok, json} = Jason.decode(json_string)
    
    # Define the schema for a review
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
    
    # Define the schema for dimensions
    dimensions_schema = %{
      "type" => "object",
      "required" => ["depth", "width", "height"],
      "properties" => %{
        "depth" => %{"type" => "number", "minimum" => 0},
        "width" => %{"type" => "number", "minimum" => 0},
        "height" => %{"type" => "number", "minimum" => 0}
      }
    }
    
    # Define the schema for meta
    meta_schema = %{
      "type" => "object",
      "properties" => %{
        "qrCode" => %{"type" => "string", "format" => "uri"},
        "barcode" => %{"type" => "string"},
        "createdAt" => %{"type" => "string", "format" => "date-time"},
        "updatedAt" => %{"type" => "string", "format" => "date-time"}
      }
    }
    
    # Define the product schema
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

    # Compile the schema
    schema = ExJsonSchema.Schema.resolve(product_schema)
    
    # Validate the JSON against the schema
    case ExJsonSchema.Validator.validate(schema, json) do
      :ok -> 
        IO.puts("JSON is valid according to the schema!")
        {:ok, "Valid"}
      {:error, errors} ->
        IO.puts("JSON validation failed!")
        IO.inspect(errors, label: "Validation errors")
        {:error, errors}
    end
  end
end

# Check if ex_json_schema is available
unless Code.ensure_loaded?(ExJsonSchema) do
  Mix.install([
    {:ex_json_schema, "~> 0.10.0"},
    {:jason, "~> 1.4"}
  ])
end

# JSON string to validate (should be passed as an argument)
json_string = System.argv() |> Enum.at(0)

if json_string == nil do
  IO.puts("Error: No JSON string provided!")
  IO.puts("Usage: mix run test/validate_json.exs '{\"json\": \"content\"}'")
  System.halt(1)
end

# Validate the JSON
JsonValidator.validate_product_json(json_string)