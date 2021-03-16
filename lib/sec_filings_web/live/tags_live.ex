defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  def get_tags(cik, adsh) do
    tag_docs = SecFilings.NumberExtractor.get_tag_docs(gen_filename(cik, adsh))
    extracted = SecFilings.NumberExtractor.extract_tags(tag_docs)
  end

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")
    tags = get_tags(cik, adsh)

    {:ok, assign(socket, tags: tags, adsh: adsh, cik: cik)}
  end
end
