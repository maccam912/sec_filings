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
      |> Enum.sort_by(
        fn {_, %{"period" => pd}} ->
          case pd do
            %{"instant" => pd} -> Date.add(pd, -1)
            %{"endDate" => pd} -> pd
          end
        end,
        {:desc, Date}
      )

    {:ok, assign(socket, tags: tag_pairs, adsh: adsh, cik: cik, query: "", feedback: "")}
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
