defmodule MainApp.ExternalInventories.ApiImpl do
  @moduledoc """
  This module provides a centralized way to access the implementation 
  of behavior-based APIs in the external inventories context.
  
  It allows dynamic configuration of the implementation to use at runtime,
  which makes it easier to swap implementations for testing.
  """

  @doc """
  Returns the module that implements the DummyProductFetchAPI behavior.
  
  This will return the configured implementation in the application config,
  or default to MainApp.ExternalInventories.DummyProductFetchAPIImpl.
  """
  def get_dummy_product_fetch_api do
    Application.get_env(
      :main_app,
      :dummy_product_fetch_api,
      MainApp.ExternalInventories.DummyProductFetchAPIImpl
    )
  end
end