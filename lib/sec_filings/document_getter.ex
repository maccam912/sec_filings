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
  def download_doc(cik, adsh) do
    wasabi_url = "https://s3.wasabisys.com/sec-filings/#{adsh}.txt.gz"

    body =
      case HTTPoison.get(
             wasabi_url,
             %{"User-Agent" => "SecFilings/1.0"},
             hackney: [pool: :first_pool]
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          [body] |> StreamGzip.gunzip() |> Enum.into("")

        _ ->
          case doc_from_sec =
                 HTTPoison.get(
                   SecFilings.Util.generate_url(cik, adsh),
                   %{"User-Agent" => "SecFilings/1.0"},
                   hackney: [pool: :first_pool]
                 ) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
              body

            _ ->
              nil
          end
      end

    # true = Cachex.put!(:filings_cache, adsh, body)
    body
  end

  def get_doc(cik, adsh) do
    download_doc(cik, adsh)
    # Cachex.get!(:filings_cache, adsh) || download_doc(cik, adsh)
  end
end
