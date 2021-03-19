defmodule SecFilings.NumberExtractor do
  def get_doc(url) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url)
    true = Cachex.put!(:filings_cache, url, body)
    body
  end

  def scan_for_tags(body) do
    Regex.scan(~r/<us-gaap:[^>]*>[^<]*<\/us-gaap:[^>]*>/s, body)
  end

  def get_tags(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"

    body =
      if Mix.env() in [:dev, :test] do
        get_doc(url)
      else
        Cachex.get!(:filings_cache, url) || get_doc(url)
      end
      |> String.replace("\n", "")

    scan_for_tags(body)
    |> Enum.map(fn [doc] -> SecFilings.TagParser.parse(doc) end)
  end

  @spec get_contexts(any) :: any
  def get_contexts(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"

    body =
      if Mix.env() in [:dev, :test] do
        get_doc(url)
      else
        Cachex.get!(:filings_cache, url) || get_doc(url)
      end
      |> String.replace("\n", "")

    IO.inspect(Regex.scan(~r/<context[^>]*>[^<]*<\/context>/s, body))

    Regex.scan(~r/<context[^>]*>[^<]*<\/context>/s, body)
    |> Enum.map(fn [doc] -> :erlsom.simple_form(doc) end)
  end

  def fixed_value_gaap_tags(tags) do
    tags
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      case v do
        %{"fixed_value" => _} -> Map.put(acc, k, v)
        _ -> acc
      end
    end)
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      if String.contains?(k, "us-gaap") do
        Map.put(acc, k, v)
      else
        acc
      end
    end)
  end
end
