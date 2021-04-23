defmodule SecFilingsWeb.CikLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @tags %{
    "NetIncomeLoss" => "Earnings",
    "Revenues" => "Sales",
    "RevenueFromContractWithCustomerExcludingAssessedTax" => "Sales",
    "SalesRevenueNet" => "Sales",
    "SalesRevenueGoodsNet" => "Sales",
    "NetCashProvidedByUsedInOperatingActivities" => "Operating Cash Flow",
    "NetCashProvidedByUsedInOperatingActivitiesContinuingOperations" => "Operating Cash Flow",
    "NetCashProvidedByUsedInInvestingActivities" => "CapEx",
    "NetCashProvidedByUsedInInvestingActivitiesContinuingOperations" => "CapEx"
  }

  def get_adsh(filename) do
    adsh_txt = List.last(String.split(filename, ["/"]))
    List.first(String.split(adsh_txt, ["."]))
  end

  def get_tags(cik) do
    # Get all filings for a company, we only need index_ids
    filings_q =
      from i in SecFilings.Raw.Index,
        where: i.form_type in ["10-K", "10-Q"] and i.cik == ^cik,
        select: i.id

    # Get contexts with index_id in our filing_q index_ids, keep context_id
    contexts_q =
      from c in SecFilings.Context,
        join: i in subquery(filings_q),
        where: i.id == c.index_id,
        select: %{id: c.id, start_date: c.start_date, end_date: c.end_date}

    # Find all tags with a context_id in contexts_q
    tags_q =
      from t in SecFilings.Tag,
        join: c in subquery(contexts_q),
        where: t.context_id == c.id and t.tag in ^Map.keys(@tags),
        select: %{tag: t.tag, value: t.value, start_date: c.start_date, end_date: c.end_date}

    SecFilings.Repo.all(tags_q)
  end

  def fix_tag(map) do
    %{map | :tag => Map.get(@tags, map.tag)}
  end

  @impl true
  def mount(params, _session, socket) do
    filings =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where:
            c.form_type in ["10-K", "10-Q"] and c.cik == ^Map.get(params, "cik") and c.status == 1,
          order_by: [desc: :date_filed, asc: :form_type]
      )

    socket =
      assign(socket,
        params: params,
        cik: Map.get(params, "cik"),
        tables: filings,
        debug: "",
        data: []
      )

    send(self(), :update_chart)
    {:ok, socket}
  end

  @impl true
  def handle_info(:update_chart, socket) do
    {cik, ""} = Integer.parse(socket.assigns.cik)

    tags =
      get_tags(cik)
      |> Enum.map(&fix_tag/1)

    socket = assign(socket, data: tags)
    socket = push_event(socket, "data", %{data: tags})

    {:noreply, socket}
  end
end
