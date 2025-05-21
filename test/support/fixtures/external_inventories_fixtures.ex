defmodule MainApp.ExternalInventoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MainApp.ExternalInventories` context.
  """

  @doc """
  Generate a dummy_product_import.
  """
  def dummy_product_import_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        job_interval_in_seconds: "3600",
        name: "some name",
        url: "some url"
      })

    {:ok, dummy_product_import} =
      MainApp.ExternalInventories.create_dummy_product_import(scope, attrs)

    dummy_product_import
  end
end
