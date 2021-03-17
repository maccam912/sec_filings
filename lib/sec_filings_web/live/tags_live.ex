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

    send(self(), :update)

    {:ok,
     assign(socket,
       adsh: adsh,
       cik: cik,
       documents: [],
       revenue: 0,
       loading: true
     )}
  end

  @impl true
  def handle_info(:update, socket) do
    cik = socket.assigns.cik
    adsh = socket.assigns.adsh
    documents = Cachex.get!(:filings_cache, {cik, adsh})

    socket =
      if is_nil(documents) do
        put_flash(socket, :info, "Form not cached. Give us 60 seconds...")
      else
        socket
      end

    send(self(), :get_documents)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:get_documents, socket) do
    cik = socket.assigns.cik
    adsh = socket.assigns.adsh

    documents =
      SecFilings.NumberExtractor.get_documents(cik, adsh)
      |> Enum.filter(fn document -> length(document[:reports]) > 0 end)

    revenue_doc =
      documents
      |> Enum.filter(fn %{reports: reports} ->
        reports
        |> Enum.reduce(false, fn item, acc ->
          acc || Map.has_key?(item, :revenue)
        end)
      end)
      |> List.first()

    %{revenue: revenue} =
      Enum.reduce(revenue_doc[:reports], %{}, fn item, acc -> Map.merge(acc, item) end)

    socket = clear_flash(socket)
    {:noreply, assign(socket, documents: documents, revenue: revenue, loading: false)}
  end
end
