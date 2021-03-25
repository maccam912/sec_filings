defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false
  require IEx

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")

    tag_pairs = SecFilings.TagExtractor.get_tag_pairs(cik, adsh)

    {:ok,
     assign(socket,
       tags: tag_pairs,
       adsh: adsh,
       cik: cik,
       query: ""
     )}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, assign(socket, query: query)}
  end
end
