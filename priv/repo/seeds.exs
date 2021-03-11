# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SecFilings.Repo.insert!(%SecFilings.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

years = 2005..2010
# years = 2020..2021
qtrs = ["QTR1", "QTR2", "QTR3", "QTR4"]

urls =
  years
  |> Enum.flat_map(fn year ->
    qtrs
    |> Enum.map(fn qtr ->
      "https://www.sec.gov/Archives/edgar/full-index/#{year}/#{qtr}/xbrl.idx"
    end)
  end)

indices =
  urls
  |> Flow.from_enumerable()
  |> Flow.flat_map(fn url ->
    SecFilings.EdgarClient.get_index(url)
  end)
  |> Enum.to_list()

IO.puts("Done downloading contents. Inserting into DB...")

indices
|> Flow.from_enumerable()
|> Flow.filter(fn item -> not is_nil(item) end)
|> Flow.map(fn item ->
  SecFilings.Raw.create_index(item)
end)
|> Enum.to_list()

IO.puts("Done inserting into DB")
