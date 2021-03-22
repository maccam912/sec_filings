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

    earnings =
      SecFilings.Repo.all(
        from e in SecFilings.Earnings,
          where: e.cik == ^Map.get(params, "cik"),
          order_by: [desc: :date]
      )

    socket =
      assign(socket,
        params: params,
        cik: Map.get(params, "cik"),
        tables: companies,
        earnings: earnings,
        debug: "",
        feedback: ""
      )

    socket = socket |> push_event("data", %{data: get_chart(earnings)})
    {:ok, socket}
  end

  def get_chart(earnings) do
    data =
      earnings
      |> Enum.map(fn item -> [item.date, item.earnings] end)

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
      send(self(), :update_earnings)
    end)
    |> Enum.to_list()

    {:noreply, socket}
  end

  @impl true
  def handle_event(:update_earnings, params, socket) do
    earnings =
      SecFilings.Repo.all(
        from e in SecFilings.Earnings,
          where: e.cik == ^Map.get(params, "cik"),
          order_by: [desc: :date]
      )

    {:noreply, assign(socket, earnings: earnings)}
  end

  def get_eps_step1(filename) do
    IO.inspect(filename)
    [_, _, cik, adsh, _] = String.split(filename, ["/", "."])

    tags =
      SecFilingsWeb.TagsLive.get_tags(cik, adsh)
      |> Enum.filter(fn {_, %{"value" => v}} -> is_number(v) end)

    tags
  end

  def get_eps_step2(filename, tags) do
    IO.puts("Processing #{filename}")
    [_, _, cik, adsh, _] = String.split(filename, ["/", "."])

    periods =
      SecFilings.NumberExtractor.get_periods(SecFilingsWeb.TagsLive.gen_filename(cik, adsh))

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

    earnings = check_for_earnings(tag_pairs, cik)
    earnings
  end

  def check_for_earnings(tag_pairs, cik) do
    tag_pairs
    |> Enum.filter(fn {k, v} ->
      String.contains?(k, "EarningsPerShareDiluted") &&
        case v do
          %{"period" => %{"startDate" => _, "endDate" => _}} -> true
          _ -> false
        end
    end)
    |> Enum.filter(fn {_, %{"period" => %{"startDate" => s, "endDate" => e}}} ->
      d = Date.diff(e, s)
      80 < d && d < 100
    end)
    |> Enum.map(fn {_, %{"period" => %{"startDate" => s, "endDate" => e}, "value" => v}} ->
      d = Date.diff(e, s)
      {cik, ""} = Integer.parse(cik)

      changeset =
        SecFilings.Earnings.changeset(%SecFilings.Earnings{}, %{
          cik: cik,
          date: e,
          period: d,
          earnings: v
        })

      SecFilings.Repo.insert(changeset)
      {v, e}
    end)
    |> Enum.uniq()
  end
end
