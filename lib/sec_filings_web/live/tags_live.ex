defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  def get_tags(cik, adsh) do
    tags = SecFilings.NumberExtractor.get_tags(gen_filename(cik, adsh))
    IO.inspect(SecFilings.NumberExtractor.tags_map(tags))
  end

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")
    tags = get_tags(cik, adsh)

    {:ok, assign(socket, tags: tags, adsh: adsh, cik: cik)}
  end
end
