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

  def check_for_earnings(tag_pairs) do
    tag_pairs
    |> Enum.filter(fn {k, v} ->
      String.contains?(k, "Earnings") &&
        case v do
          %{"period" => %{"startDate" => _, "endDate" => _}} -> true
          _ -> false
        end
    end)
    |> Enum.filter(fn {_, %{"period" => %{"startDate" => s, "endDate" => e}}} ->
      d = Date.diff(e, s)
      80 < d && d < 100
    end)
    |> Enum.map(fn {_, %{"period" => %{"endDate" => e}, "value" => v}} -> {v, e} end)
  end

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")

    tags =
      get_tags(cik, adsh)
      |> Enum.filter(fn {_, %{"value" => v}} -> is_number(v) end)

    periods = SecFilings.NumberExtractor.get_periods(gen_filename(cik, adsh))

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

    earnings = check_for_earnings(tag_pairs)

    {:ok,
     assign(socket,
       earnings: earnings,
       tags: tag_pairs,
       adsh: adsh,
       cik: cik,
       query: "",
       feedback: ""
     )}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, assign(socket, query: query)}
  end

  @impl true
  def handle_event("feedback", %{"feedback" => feedback}, socket) do
    fb = %SecFilings.SecFilings.Feedback{feedback: feedback}
    SecFilings.Repo.insert(fb)
    {:noreply, assign(socket, feedback: "Thanks!")}
  end
end
