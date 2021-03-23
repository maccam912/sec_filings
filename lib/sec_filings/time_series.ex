defmodule SecFilings.TimeSeries do
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

  def get_tag_pairs_with_period_instant(tag_pairs, tag) do
    tag_pairs
    |> Enum.filter(fn {k, v} ->
      String.contains?(k, tag) &&
        case v do
          %{"period" => %{"instant" => _}} -> true
          _ -> false
        end
    end)
  end

  def get_tag_pairs_with_period_duration(tag_pairs, tag) do
    tag_pairs
    |> Enum.filter(fn {k, v} ->
      String.contains?(k, tag) &&
        case v do
          %{"period" => %{"startDate" => _, "endDate" => _}} -> true
          _ -> false
        end
    end)
    |> Enum.filter(fn {_, %{"period" => %{"startDate" => s, "endDate" => e}}} ->
      d = Date.diff(e, s)
      80 < d && d < 100
    end)
  end

  def check_for_earnings(tag_pairs, cik, tag) do
    get_tag_pairs_with_period_duration(tag_pairs, tag)
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

  def check_for_earnings(tag_pairs, cik) do
    ["EarningsPerShareDiluted", "EarningsPerShareBasicAndDiluted", "EarningsPerShareBasic"]
    # This is Enum on purpose! I want it to add in the order above, filling in gaps as it can
    |> Enum.flat_map(fn tag -> check_for_earnings(tag_pairs, cik, tag) end)
    |> Enum.uniq()
  end

  def check_for_outstanding_shares(tag_pairs, cik) do
    get_tag_pairs_with_period_instant(tag_pairs, "CommonStockSharesOutstanding")
    |> Enum.map(fn {_, %{"period" => %{"instant" => e}, "value" => v}} ->
      {cik, ""} = Integer.parse(cik)

      changeset =
        SecFilings.SharesOutstanding.changeset(%SecFilings.SharesOutstanding{}, %{
          cik: cik,
          date: e,
          shares_outstanding: round(v)
        })

      SecFilings.Repo.insert(changeset)
      {v, e}
    end)
    |> Enum.uniq()
  end
end
