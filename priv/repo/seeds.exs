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

years = 2010..2020
qtrs = ["QTR1", "QTR2", "QTR3", "QTR4"]

years
|> Flow.from_enumerable()
|> Flow.flat_map(fn year ->
  qtrs
  |> Flow.from_enumerable()
  |> Flow.flat_map(fn qtr ->
    IO.puts("#{year} #{qtr}")
    url = "https://www.sec.gov/Archives/edgar/full-index/#{year}/#{qtr}/xbrl.idx"

    SecFilings.EdgarClient.get_index(url)
    |> Flow.from_enumerable()
    |> Flow.map(fn map -> SecFilings.Raw.create_index(map) end)
  end)
end)
|> Enum.to_list()
