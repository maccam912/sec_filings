defmodule SecFilingsWeb.LoadLatestLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    send(self(), :update)
    done = SecFilings.Repo.one(from i in SecFilings.ParsedDocument, select: count(i.id))
    total = SecFilings.Repo.one(from i in SecFilings.Raw.Index, select: count(i.id))
    {:ok, assign(socket, done: done, total: total)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    done = SecFilings.Repo.one(from i in SecFilings.ParsedDocument, select: count(i.id))
    total = SecFilings.Repo.one(from i in SecFilings.Raw.Index, select: count(i.id))
    Process.send_after(self(), :refresh, 10000)
    {:ok, assign(socket, done: done, total: total)}
  end

  @impl true
  def handle_info(:update, state) do
    years = 2021..2021
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

    indices
    |> Flow.from_enumerable()
    |> Flow.filter(fn item -> not is_nil(item) end)
    |> Flow.map(fn item ->
      SecFilings.Raw.create_index(item)
    end)
    |> Enum.to_list()

    Process.send_after(self(), :refresh, 1000)
    {:noreply, state}
  end
end
