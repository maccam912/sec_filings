defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")

    {:ok,
     assign(socket,
       adsh: adsh,
       cik: cik,
       documents: SecFilings.NumberExtractor.get_documents(cik, adsh)
     )}
  end
end
