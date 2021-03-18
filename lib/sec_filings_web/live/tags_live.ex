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

    ordered_tag_keys =
      tags
      |> Enum.filter(fn {_, %{"value" => v}} ->
        is_float(v)
      end)
      |> Enum.sort_by(fn {_, %{"value" => v}} ->
        -1 * v
      end)
      |> Enum.map(fn {k, _} -> k end)

    tags_map =
      tags
      |> Enum.reduce(%{}, fn {name, content}, acc ->
        Map.put(acc, name, content)
      end)

    {:ok, assign(socket, tags: tags_map, tag_keys: ordered_tag_keys, adsh: adsh, cik: cik)}
  end
end
