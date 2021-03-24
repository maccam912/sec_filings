defmodule SecFilingsWeb.CikLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @tags %{
    "NetIncomeLoss" => "Earnings",
    "CommonStockSharesOutstanding" => "Shares Outstanding",
    "Revenues" => "Sales",
    "RevenueFromContractWithCustomerExcludingAssessedTax" => "Sales",
    "NetCashProvidedByUsedInOperatingActivities" => "Operating Cash Flow"
  }

  def get_adsh(filename) do
    adsh_txt = List.last(String.split(filename, ["/"]))
    List.first(String.split(adsh_txt, ["."]))
  end

  @impl true
  def mount(params, _session, socket) do
    filings =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"] and c.cik == ^Map.get(params, "cik"),
          order_by: [desc: :date_filed, asc: :form_type]
      )

    tags =
      SecFilings.Repo.all(
        from t in SecFilings.TagPairs,
          where: t.cik == ^Map.get(params, "cik") and t.tag in ^Map.keys(@tags),
          order_by: [desc: :end_date]
      )

    data =
      tags
      |> Enum.filter(fn item ->
        item.tag in Map.keys(@tags)
      end)
      |> Enum.filter(fn item ->
        d = Date.diff(item.end_date, item.start_date)
        (80 < d && d < 100) || d == 0
      end)
      |> Enum.map(fn item -> {item.end_date, item.tag, item.value} end)
      |> Enum.reduce(%{}, fn {date, tag, value}, acc ->
        fixed_tag = @tags[tag]
        Map.update(acc, date, %{fixed_tag => value}, fn old -> Map.put(old, fixed_tag, value) end)
      end)

    # |> Enum.map(fn {k, v} ->
    #   v
    #   Enum.reduce(%{date: k}, fn {tag, value}, acc ->
    #     Map.put(acc, tag, value)
    #   end)
    # end)

    socket =
      assign(socket,
        params: params,
        cik: Map.get(params, "cik"),
        tables: filings,
        debug: "",
        feedback: ""
      )

    socket = socket |> push_event("data", %{data: data})
    {:ok, socket}
  end

  def get_chart(earnings) do
    data =
      earnings
      |> Enum.map(fn item ->
        [item.date, item.earnings, item.shares_outstanding, item.total_earnings]
      end)

    data
  end

  @impl true
  def handle_event("feedback", %{"feedback" => feedback}, socket) do
    fb = %SecFilings.Feedback{feedback: feedback}
    SecFilings.Repo.insert(fb)
    {:noreply, assign(socket, feedback: "Thanks!")}
  end

  @impl true
  def handle_event("get_tags", _params, socket) do
    cik = socket.assigns.cik
    SecFilings.TagExtractorWorker.load_cik(cik)
    {:noreply, socket}
  end
end
