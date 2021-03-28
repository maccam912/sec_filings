defmodule SecFilingsWeb.CikLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @tags %{
    "NetIncomeLoss" => "Earnings",
    "CommonStockSharesOutstanding" => "Shares Outstanding",
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
    filings_q =
      from i in SecFilings.Raw.Index,
        join: parsed_documents in assoc(i, :parsed_documents),
        where:
          i.form_type in ["10-K", "10-Q"] and i.cik == ^cik and
            not is_nil(parsed_documents)

    contexts_q =
      from c in SecFilings.Context,
        join: i in subquery(filings_q),
        where: i.id == c.index_id

    tags_q =
      from t in SecFilings.Tag,
        join: c in subquery(contexts_q),
        where: t.context_id == t.id and t.tag in ^Map.keys(@tags)

    SecFilings.Repo.all(tags_q)
  end

  @impl true
  def mount(params, _session, socket) do
    filings =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          left_join: parsed_documents in assoc(c, :parsed_documents),
          where:
            c.form_type in ["10-K", "10-Q"] and c.cik == ^Map.get(params, "cik") and
              not is_nil(parsed_documents),
          order_by: [desc: :date_filed, asc: :form_type]
      )

    tags = IO.inspect(get_tags(Map.get(params, "cik")))

    socket =
      assign(socket,
        params: params,
        cik: Map.get(params, "cik"),
        tables: filings,
        debug: "",
        data: tags
      )

    {:ok, socket}
  end
end
