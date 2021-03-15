defmodule SecFilings.NumberExtractor do
  require IEx

  def get_tags(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url)
    doc = Floki.parse_document!(body)
    tags = IO.inspect(Floki.find(doc, "ix:nonfraction"))
    IEx.pry()
    tags
  end

  def tags_map(tags) do
    tags
    |> Enum.map(fn {"ix:nonfraction", [attrs], value} ->
      {"k", value}
    end)
  end

  def old_get_tags(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url)
    numbers = Regex.scan(~r/<ix:nonFraction[^>]*>[^<]*<\/ix:nonFraction>/, body)
    numbers
  end

  def extract_tag(item) do
    IO.inspect(Floki.parse_document(item))
    name = Regex.run(~r/.*name="([^"]*)"/, item)
    value = Regex.run(~r/<ix:nonFraction[^>]*>(.*)<\/ix:nonFraction>/, item)
    {Enum.at(name, 1), Enum.at(value, 1)}
  end

  def old_tags_map(tags) do
    tags
    |> Enum.flat_map(fn item -> item end)
    |> Enum.map(fn item -> extract_tag(item) end)
    |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      Map.put(acc, k, v)
    end)
  end
end
