defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  def get_tags(cik, adsh) do
    SecFilings.NumberExtractor.get_tags(gen_filename(cik, adsh))
  end

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")
    tags = get_tags(cik, adsh)

    tags_map =
      tags
      |> Enum.reduce(%{}, fn {name, content}, acc ->
        Map.put(acc, name, content)
      end)

    ordered_tag_keys =
      Map.keys(tags_map)
      |> Enum.filter(fn key ->
        is_float(Map.get(Map.get(tags_map, key), "value"))
      end)

    {:ok, assign(socket, tags: tags_map, tag_keys: ordered_tag_keys, adsh: adsh, cik: cik)}
  end
end
