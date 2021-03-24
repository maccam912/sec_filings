defmodule SecFilingsWeb.CikLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @tags %{
    "NetIncomeLoss" => "Earnings",
    "CommonStockSharesOutstanding" => "Shares Outstanding",
    "Revenues" => "Sales",
    "RevenueFromContractWithCustomerExcludingAssessedTax" => "Sales",
    "NetCashProvidedByUsedInOperatingActivities" => "Operating Cash Flow",
    "NetCashProvidedByUsedInInvestingActivities" => "CapEx"
  }

  def get_adsh(filename) do
    adsh_txt = List.last(String.split(filename, ["/"]))
    List.first(String.split(adsh_txt, ["."]))
  end

  def get_latest_data(cik) do
    tags =
      SecFilings.Repo.all(
        from t in SecFilings.TagPairs,
          where: t.cik == ^cik and t.tag in ^Map.keys(@tags),
          order_by: [desc: :end_date]
      )

    tags
    |> Enum.filter(fn item ->
      item.tag in Map.keys(@tags)
    end)
    |> Enum.map(fn item ->
      d = Date.diff(item.end_date, item.start_date)

      v =
        if item.tag in ["InterestExpense"] do
          -1 * item.value
        else
          item.value
        end

      case d do
        0 -> {item.end_date, item.tag, v}
        _ -> {item.end_date, item.tag, v / d}
      end
    end)
    |> Enum.reduce(%{}, fn {date, tag, value}, acc ->
      Map.update(acc, date, %{tag => value}, fn old -> Map.put(old, tag, value) end)
    end)
    |> Enum.reduce(%{}, fn {date, map}, acc ->
      map =
        Enum.reduce(%{}, map, fn {k, v}, acc ->
          map = Map.put(acc, k, v)

          map =
            if k in Map.keys(@tags) do
              Map.put(map, @tags[k], v)
            else
              map
            end

          map
        end)

      Map.put(acc, date, map)
    end)
  end

  @impl true
  def mount(params, _session, socket) do
    filings =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"] and c.cik == ^Map.get(params, "cik"),
          order_by: [desc: :date_filed, asc: :form_type]
      )

    socket =
      assign(socket,
        params: params,
        cik: Map.get(params, "cik"),
        tables: filings,
        debug: "",
        feedback: "",
        data: %{}
      )

    send(self(), "refresh_chart")
    {:ok, socket}
  end

  def handle_info("refresh_chart", socket) do
    cik = socket.assigns.cik
    latest_data = get_latest_data(cik)

    socket =
      if latest_data != socket.assigns.data do
        socket = assign(socket, data: latest_data)
        socket = socket |> push_event("data", %{data: latest_data})
        socket
      else
        socket
      end

    Process.send_after(self(), "refresh_chart", 3000)
    {:noreply, socket}
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
