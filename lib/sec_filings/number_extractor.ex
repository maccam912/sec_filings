defmodule SecFilings.NumberExtractor do
  def get_tag_docs(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url)
    numbers = Regex.scan(~r/<ix:nonFraction[^>]*>[^<]*<\/ix:nonFraction>/, body)
    numbers
  end

  def extract_tags(tag_docs) do
    tag_docs
    |> Enum.map(fn item ->
      [{"ix:nonfraction", attrs, [num]}] = Floki.parse_document!(item)

      fixed_num =
        num
        |> String.replace(",", "")
        |> String.replace("$", "")

      parsed_num = Float.parse(fixed_num)

      new_attrs =
        Enum.reduce(attrs, %{}, fn {name, value}, acc ->
          Map.put(acc, name, value)
        end)

      {new_attrs, parsed_num}
    end)
    |> Enum.filter(fn {_, parsed_num} ->
      parsed_num != :error
    end)
    |> Enum.map(fn {attrs, {num, _}} ->
      {dec_movement, ""} = Integer.parse(Map.get(attrs, "scale"))
      scaled_num = num * :math.pow(10, dec_movement)
      Map.put(attrs, "value", num)
      Map.put(attrs, "fixed_value", scaled_num)
    end)
    |> Enum.reduce(%{}, fn item, acc ->
      Map.put(acc, Map.get(item, "name"), item)
    end)
  end
end
