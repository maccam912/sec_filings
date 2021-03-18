defmodule SecFilings.TagParser do
  def parse(doctext) do
    try do
      {:ok, element, _tail} = :erlsom.simple_form(doctext)
      {tag, attributes, content} = element
      tag = to_string(tag)

      attr_map =
        Enum.reduce(attributes, %{}, fn {key, value}, acc ->
          Map.put(acc, to_string(key), to_string(value))
        end)

      attr_map = Map.put(attr_map, "content", content |> Enum.map(&to_string/1))

      [value] = Map.get(attr_map, "content")

      attr_map =
        try do
          {scaled_value, ""} = Float.parse(value)

          real_value = scaled_value
          # try do
          #   {dec, ""} = Map.get(attr_map, "decimals") |> Float.parse()
          #   factor = :math.pow(10, dec * -1)
          #   real_value = scaled_value * factor
          #   real_value
          # rescue
          #   _ -> scaled_value
          # end

          Map.put(attr_map, "value", real_value)
        rescue
          MatchError -> Map.put(attr_map, "value", value)
        end

      {tag, attr_map}
    catch
      _ -> nil
    end
  end
end
