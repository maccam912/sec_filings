defmodule SecFilings.TagExtractor do
  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  def get_tags(cik, adsh) do
    SecFilings.NumberExtractor.get_tags(gen_filename(cik, adsh))
  end

  def get_tag_pairs(cik, adsh) do
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

    tag_pairs
  end
end
