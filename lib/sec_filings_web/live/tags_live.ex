defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  def get_tags(cik, adsh) do
    tag_docs = SecFilings.NumberExtractor.get_tag_docs(gen_filename(cik, adsh))
    extracted = SecFilings.NumberExtractor.extract_tags(tag_docs)
    SecFilings.NumberExtractor.fixed_value_gaap_tags(extracted)
  end

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")
    tags = get_tags(cik, adsh)

    ordered_tag_keys =
      tags
      |> Enum.sort_by(fn {_, v} ->
        -1 * Map.get(v, "fixed_value")
      end)
      |> Enum.map(fn {k, _} -> k end)

    {:ok, assign(socket, tags: tags, tag_keys: ordered_tag_keys, adsh: adsh, cik: cik)}
  end
end
