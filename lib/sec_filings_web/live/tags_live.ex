defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false
  require IEx

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

    tags =
      get_tags(cik, adsh)
      |> Enum.filter(fn {_, %{"value" => v}} -> is_number(v) end)

    # |> Enum.sort_by(fn {_, %{"value" => v}} -> -v end)

    contexts = SecFilings.NumberExtractor.get_contexts(gen_filename(cik, adsh))
    # IEx.pry()

    {:ok, assign(socket, tags: tags, adsh: adsh, cik: cik, query: "")}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, assign(socket, query: query)}
  end
end
