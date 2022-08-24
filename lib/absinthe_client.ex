defmodule AbsintheClient do
  @moduledoc """
  High-level API for Elixir with GraphQL.

  AbsintheClient is composed of three main pieces:

    * `AbsintheClient` - the high-level API (you're here!)

    * `AbsintheClient.Request` - the low-level API and HTTP plugin

    * AbsintheClient.Subscription - TODO

  """

  @doc """
  Returns a new request struct with GraphQL steps.

  ## Examples

      iex> client = AbsintheClient.new()
      iex> client.method
      :post

  """
  @spec new(options :: keyword) :: AbsintheClient.Request.t()
  def new(options \\ []) do
    {absinthe_options, req_options} = Keyword.split(options, [:query, :variables])
    AbsintheClient.Request.attach(Req.new([method: :post] ++ req_options), absinthe_options)
  end

  @doc ~S"""
  Makes a GraphQL query and returns a response or raises an error.

  ## Examples

      iex> url = Absinthe.SocketTest.Endpoint.graphql_url()
      iex> AbsintheClient.query!(url, query: "query { getItem(id: FOO){ id } }").status
      200

  """
  @spec query!(String.t() | AbsintheClient.Request.t()) :: AbsintheClient.Response.t()
  def query!(url_or_request, options \\ [])

  def query!(%Req.Request{} = request, options) do
    request!(request, options)
  end

  def query!(url, options) do
    request!([url: URI.parse(url)] ++ options)
  end

  @spec request(AbsintheClient.Request.t() | keyword()) ::
          {:ok, AbsintheClient.Response.t()} | {:error, Exception.t()}
  def request(request_or_options)

  def request(%Req.Request{} = request) do
    case Req.request(request) do
      {:ok, %Req.Response{} = response} ->
        run_response(request, response)

      {:error, %{__exception__: true} = exception} ->
        run_error(request, exception)
    end
  end

  def request(options) do
    request(AbsintheClient.new(options))
  end

  @doc """
  Makes an HTTP request.

  See `request/1` for more information.

  """
  @spec request(AbsintheClient.Request.t(), options :: keyword()) ::
          {:ok, AbsintheClient.Response.t()} | {:error, Exception.t()}
  def request(request, options) when is_list(options) do
    case Req.request(request, options) do
      {:ok, response} -> run_response(request, response)
      {:error, exception} -> run_error(request, exception)
    end
  end

  @doc """
  Makes an HTTP request and returns a response or raises an error.

  See `request/1` for more information.

  ## Examples

      iex> url = Absinthe.SocketTest.Endpoint.graphql_url()
      iex> AbsintheClient.request!(url: url, query: "query { getItem(id: FOO){ id } }").status
      200

  """
  @spec request!(AbsintheClient.Request.t() | keyword()) :: AbsintheClient.Response.t()
  def request!(request_or_options) do
    case request(request_or_options) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Makes an HTTP request and returns a response or raises an error.

  See `request/1` for more information.

  ## Examples

      iex> client = AbsintheClient.new(base_url: Absinthe.SocketTest.Endpoint.url())
      iex> AbsintheClient.request!(client, url: "/graphql", query: "query { getItem(id: FOO){ id } }").status
      200

  """
  @spec request!(AbsintheClient.Request.t(), options :: keyword()) :: AbsintheClient.Response.t()
  def request!(request, options) do
    case request(request, options) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  defp run_response(_request, resp) do
    result(%AbsintheClient.Response{
      status: resp.status,
      headers: resp.headers,
      data: resp.body["data"],
      errors: resp.body["errors"]
    })
  end

  defp run_error(_request, exception) do
    result(exception)
  end

  defp result(%AbsintheClient.Response{} = response) do
    {:ok, response}
  end

  defp result(%{__exception__: true} = exception) do
    {:error, exception}
  end
end
