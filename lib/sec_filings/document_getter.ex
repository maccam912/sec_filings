defmodule SecFilings.DocumentGetter do
  @moduledoc """
    This is the DocumentGetter module, for any work related to
    retrieving documents, including retrieving from cache vs network.
  """

  @doc """
  get_doc(url) accepts a string, a url, and downloads it with
  pool :first_pool. It then stores it in :filings_cache under the
  url as the key, and returns the body of the document.
  """
  def download_doc(url) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.get(url, [], hackney: [pool: :first_pool])

    true = Cachex.put!(:filings_cache, url, body)
    body
  end
end
