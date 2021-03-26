defmodule SecFilings.DocumentParser do
  @moduledoc """
  DocumentParser is for any work that comes after downloading the raw
  document, but not yet doing any work with the data in the document.
  This module should be used for taking data out of the document into
  a better format for use.
  """

  @doc """
  get_tag_strings(body) takes in a raw document body as a string and
  uses a quick Regex pattern to extract all the lines that are using
  the tag <us-gaap:...>. It returns a list of strings, each one a single
  <us-gaap:...>...</...> tag.
  """
  def get_tag_strings(body) do
    Regex.scan(~r/<us-gaap:[^>]*>[^<]*<\/us-gaap:[^>]*>/s, body)
    |> List.flatten()
  end

  def parse_tag_string(tag_string) do
    {:ok, node, _tail} = :erlsom.simple_form(tag_string)
    {tag, attr_list, [content]} = node

    value =
      case Float.parse(to_string(content)) do
        {value, ""} -> value
        _ -> content
      end

    attr_map = attr_list |> Enum.into(%{})
    %{to_string(tag) => %{value: value, context: to_string(attr_map['contextRef'])}}
  end

  @doc """
  get_context_strings(body) works like get_tag_strings, but looks for
  <context...> or <xbrli:context...> tags.
  """
  def get_context_strings(body) do
    Regex.scan(~r/<(?:xbrli:)context[^>]*>.*?<\/(?:xbrli:)?context>/s, body)
    |> List.flatten()
  end

  # @doc """
  # parse_context_string(context_string) takes in a raw string of xml and uses erlsom
  # to parse out the contents. It returns a map.
  # """
  # def parse_context_string(context_string) do
  #   context_node = :erlsom.simple_form(context_string)
  #   {:ok, context_body, _tail} = parse_node(context_node)
  #   context_body
  # end

  @doc """
  get_period(context_node) expects a map from parse_context_string, and returns
  a new map containing the context ID as the key, and a
  %{"startDate" => ..., "endDate" => ...} as a value. Any "instant" periods will
  have both startDate and endDate the same.
  """
  def get_period(context_node) do
    %{"context" => %{"id" => id, "period" => period}} = context_node

    parsed_period =
      case period do
        %{"instant" => %{"text" => dt}} ->
          %{"startDate" => Datix.Date.parse!(dt, "%x"), "endDate" => Datix.Date.parse!(dt, "%x")}

        %{"startDate" => %{"text" => start_dt}, "endDate" => %{"text" => end_dt}} ->
          %{
            "startDate" => Datix.Date.parse!(start_dt, "%x"),
            "endDate" => Datix.Date.parse!(end_dt, "%x")
          }
      end

    %{id => parsed_period}
  end

  @doc """
  parse! and parse read in an entire document, then parse out all
  items using erlsom, if possible.
  """
  def parse!(document_text) do
    {:ok, element, _tail} = :erlsom.simple_form(document_text)
    {tag, attributes, content} = element
    # TODO is this necessary?
    # tag = to_string(tag)

    content_as_strings = Enum.map(content, &to_string/1)

    attr_map =
      Enum.reduce(attributes, %{}, fn {key, value}, acc ->
        Map.put(acc, to_string(key), to_string(value))
      end)
      |> Map.put("content", content_as_strings)

    # if content_as_strings is empty
    if length(content_as_strings) > 0 do
      [content_string] = content_as_strings

      parsed_value =
        case Float.parse(content_string) do
          {value_float, ""} -> value_float
          value_string -> value_string
        end

      attr_map = Map.put(attr_map, "value", parsed_value)

      {tag, attr_map}
    else
      nil
    end
  end

  def parse(document_text) do
    try do
      parsed = parse!(document_text)
      {:ok, parsed}
    catch
      _ -> {:error, nil}
    end
  end

  @doc """
  Parse node accepts either an erlsom node or a string and returns a map,
  or possibly just a %{"text" => text} if it is not an erlsom node.
  """
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
end
