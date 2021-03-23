defmodule SecFilingsWeb.CikLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

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

    socket =
      assign(socket,
        params: params,
        cik: Map.get(params, "cik"),
        tables: filings,
        debug: "",
        feedback: ""
      )

    socket = socket |> push_event("data", %{data: []})
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
    fb = %SecFilings.SecFilings.Feedback{feedback: feedback}
    SecFilings.Repo.insert(fb)
    {:noreply, assign(socket, feedback: "Thanks!")}
  end

  @impl true
  def handle_event("get_tags", _params, socket) do
    cik = socket.assigns.cik
    SecFilings.TagExtractor.load_cik(cik)
    {:noreply, socket}
  end
end
