defmodule SecFilingsWeb.CikLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  def get_adsh(filename) do
    adsh_txt = List.last(String.split(filename, ["/"]))
    List.first(String.split(adsh_txt, ["."]))
  end

  @impl true
  def mount(params, _session, socket) do
    companies =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"] and c.cik == ^Map.get(params, "cik"),
          order_by: [desc: :date_filed, asc: :form_type]
      )

    earnings_and_shares =
      SecFilings.Repo.all(
        from e in SecFilings.Earnings,
          left_join: s in SecFilings.SharesOutstanding,
          on: e.cik == s.cik and e.date == s.date,
          where: e.cik == ^Map.get(params, "cik"),
          order_by: [desc: :date],
          select: %{
            cik: e.cik,
            date: e.date,
            earnings: e.earnings,
            shares_outstanding: s.shares_outstanding
          }
      )
      |> Enum.map(fn item ->
        if !is_nil(item.earnings) and !is_nil(item.shares_outstanding) do
          Map.put(item, :total_earnings, item.earnings * item.shares_outstanding)
        end
      end)
      |> Enum.filter(fn item -> !is_nil(item) end)

    socket =
      assign(socket,
        params: params,
        cik: Map.get(params, "cik"),
        tables: companies,
        earnings: earnings_and_shares,
        debug: "",
        feedback: ""
      )

    socket = socket |> push_event("data", %{data: get_chart(earnings_and_shares)})
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
  def handle_event("get_eps", _params, socket) do
    filenames =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"] and c.cik == ^socket.assigns.cik,
          order_by: [desc: :date_filed, asc: :form_type],
          select: c.filename
      )

    filenames
    |> Flow.from_enumerable()
    |> Flow.map(fn filename ->
      {filename, get_eps_step1(filename)}
    end)
    |> Flow.map(fn {filename, tags} ->
      get_eps_step2(filename, tags)
    end)
    |> Enum.to_list()

    {:noreply, socket}
  end

  def get_eps_step1(filename) do
    IO.inspect(filename)
    [_, _, cik, adsh, _] = String.split(filename, ["/", "."])

    tags =
      SecFilings.TimeSeries.get_tags(cik, adsh)
      |> Enum.filter(fn {_, %{"value" => v}} -> is_number(v) end)

    tags
  end

  def get_eps_step2(filename, tags) do
    IO.puts("Processing #{filename}")
    [_, _, cik, adsh, _] = String.split(filename, ["/", "."])

    periods =
      SecFilings.NumberExtractor.get_periods(SecFilings.TimeSeries.gen_filename(cik, adsh))

    tags =
      tags
      |> Enum.map(fn {k, v} ->
        contextRef = Map.get(v, "contextRef")
        {k, Map.put(v, "period", Map.get(periods, contextRef))}
      end)

    tag_pairs =
      tags
      |> Enum.map(fn {k, v} -> {k, v} end)
      |> Enum.filter(fn {_, %{"period" => pd}} -> !is_nil(pd) end)
      |> Enum.sort_by(
        fn {_, %{"period" => pd}} ->
          case pd do
            %{"instant" => pd} -> Date.add(pd, -1)
            %{"endDate" => pd} -> pd
          end
        end,
        {:desc, Date}
      )

    _outstanding_shares = SecFilings.TimeSeries.check_for_outstanding_shares(tag_pairs, cik)
    earnings = Task.async(fn -> SecFilings.TimeSeries.check_for_earnings(tag_pairs, cik) end)
    Task.await(earnings)
  end
end
