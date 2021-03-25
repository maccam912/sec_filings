defmodule SecFilings.TagExtractor do
  import Ecto.Query, warn: false

  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  def get_tags(cik, adsh) do
    SecFilings.NumberExtractor.get_tags(gen_filename(cik, adsh))
  end

  def get_tag_pairs(cik, adsh) do
    tags =
      get_tags(cik, adsh)
      |> Enum.filter(fn item -> !is_nil(item) end)
      |> Enum.filter(fn {_, item} -> !is_nil(item) end)
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
      |> Enum.filter(fn {_, %{"period" => pd}} -> !is_nil(pd) end)
      |> Enum.map(fn {k, v} ->
        {k,
         case v do
           %{"period" => %{"instant" => dt}} ->
             Map.put(v, "period", %{"startDate" => dt, "endDate" => dt})

           _ ->
             v
         end}
      end)

    tag_pairs
  end

  def insert_tags(cik, adsh) do
    get_tag_pairs(cik, adsh)
    |> Flow.from_enumerable()
    |> Flow.map(fn {k, %{"value" => v, "period" => %{"startDate" => sd, "endDate" => ed}}} ->
      m = %{cik: cik, tag: k, value: v, start_date: sd, end_date: ed}
      SecFilings.TagPairs.changeset(%SecFilings.TagPairs{}, m)
    end)
    |> Flow.map(fn changeset ->
      SecFilings.Repo.insert(changeset)
    end)
    |> Flow.run()
  end

  def get_filenames_for_cik(cik) do
    SecFilings.Repo.all(
      from c in SecFilings.Raw.Index,
        where: c.form_type in ["10-K", "10-Q"] and c.cik == ^cik,
        order_by: [desc: :date_filed, asc: :form_type],
        select: c.filename
    )
  end

  def load_cik(cik) do
    get_filenames_for_cik(cik)
    |> Stream.map(fn filename ->
      get_cik_adsh(filename)
    end)
    |> Stream.map(fn {cik, adsh} ->
      SecFilings.TagExtractor.insert_tags(cik, adsh)
    end)
    |> Enum.to_list()
  end

  def get_cik_adsh(filename) do
    ["edgar", "data", cik, adsh, "txt"] = String.split(filename, ["/", "."])
    {cik, adsh}
  end
end
