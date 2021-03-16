defmodule SecFilings.NumberExtractor do
  def get_doc(url) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url)
    true = Cachex.put!(:filings_cache, url, body)
    body
  end

  def parse_desc({"description", [], [desc_text, text]}) do
    {"text", [], doc} = text

    if length(doc) == 1 do
      {String.trim(desc_text), List.first(doc)}
    else
      {String.trim(desc_text), nil}
    end
  end

  def parse_desc({"text", [], doc}) do
    {nil, doc}
  end

  def parse_single_document(doc) do
    {"document", [], [{"type", [], [type | [seq]]}]} = doc
    {"sequence", [], [seq_num, filename]} = seq
    {"filename", [], [filename, description]} = filename
    {description, doc} = parse_desc(description)

    type = String.trim(type)
    {seq_num, ""} = Integer.parse(String.trim(seq_num))
    filename = String.trim(filename)

    %{
      type: type,
      sequence_number: seq_num,
      filename: filename,
      description: description,
      text: doc
    }
  end

  def get_documents(body) do
    doc = Floki.parse_document!(body)

    Floki.find(doc, "document")
    |> Enum.map(fn doc -> parse_single_document(doc) end)
  end

  def get_tag_docs(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"
    body = Cachex.get!(:filings_cache, url) || get_doc(url)
    numbers = Regex.scan(~r/<ix:nonFraction[^>]*>[^<]*<\/ix:nonFraction>/, body)
    numbers
  end

  def extract_tags(tag_docs) do
    tag_docs
    |> Enum.map(fn item ->
      case Floki.parse_document!(item) do
        [{"ix:nonfraction", attrs, [num]}] ->
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

        [{_, _, []}] ->
          nil
      end
    end)
    |> Enum.filter(fn item -> not is_nil(item) end)
    |> Enum.filter(fn {_, parsed_num} ->
      parsed_num != :error
    end)
    |> Enum.map(fn {attrs, {num, _}} ->
      if not is_nil(Map.get(attrs, "scale")) do
        case Integer.parse(Map.get(attrs, "scale")) do
          {dec_movement, ""} ->
            scaled_num = num * :math.pow(10, dec_movement)
            Map.put(attrs, "value", num)
            Map.put(attrs, "fixed_value", scaled_num)

          _ ->
            %{}
        end
      else
        %{}
      end
    end)
    |> Enum.reduce(%{}, fn item, acc ->
      key = Map.get(item, "name")

      if not Map.has_key?(acc, key) do
        Map.put(acc, key, item)
      else
        acc
      end
    end)
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
