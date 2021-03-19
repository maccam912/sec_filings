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

    scan_for_tags(body)
    |> Enum.map(fn [doc] -> SecFilings.TagParser.parse(doc) end)
  end

  def parse_node({name, attrs, body}) do
    attrs =
      attrs
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        Map.put(acc, to_string(key), to_string(value))
      end)

    content_map =
      body
      |> Enum.map(fn item -> parse_node(item) end)
      |> Enum.reduce(%{}, fn map, acc ->
        Map.merge(acc, map)
      end)

    %{to_string(name) => Map.merge(attrs, content_map)}
  end

  def parse_node(text) do
    %{"text" => to_string(text)}
  end

  def get_contexts(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"

    body =
      if Mix.env() in [:dev, :test] do
        get_doc(url)
      else
        Cachex.get!(:filings_cache, url) || get_doc(url)
      end

    Regex.scan(~r/<context[^>]*>.*?<\/context>/s, body)
    |> Enum.map(fn [doc] -> :erlsom.simple_form(doc) end)
    |> Enum.map(fn {:ok, context_body, _tail} -> parse_node(context_body) end)
  end

  def get_periods(filename) do
    get_contexts(filename)
    |> Enum.map(fn %{"context" => %{"id" => id, "period" => period}} ->
      period =
        case period do
          %{"instant" => %{"text" => dt}} ->
            %{"instant" => Datix.Date.parse!(dt, "%x")}

          %{"startDate" => %{"text" => start_dt}, "endDate" => %{"text" => end_dt}} ->
            %{
              "startDate" => Datix.Date.parse!(start_dt, "%x"),
              "endDate" => Datix.Date.parse!(end_dt, "%x")
            }
        end

      {id, period}
    end)
    |> Enum.into(%{})
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
