defmodule MainApp.HttpClient do
  alias HTTPoison.Response
  alias HTTPoison.Error

  @callback get(String.t(), headers :: list(), options :: keyword()) ::
              {:ok, Response.t()} | {:error, Error.t()}
end

defmodule MainApp.HttpClientImpl do
  @behaviour MainApp.HttpClient

  def get(url, headers \\ [], options \\ []) do
    HTTPoison.get(url, headers, options)
  end
end
