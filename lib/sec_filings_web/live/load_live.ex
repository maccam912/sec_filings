defmodule SecFilingsWeb.LoadLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    2005..2021
    |> Enum.map(fn year ->
      ["QTR1", "QTR2", "QTR3", "QTR4"]
      |> Enum.map(fn qtr ->
        send(self(), {:load, year, qtr})
      end)
    end)

    {:ok, assign(socket, progress: [], num_rows: 0)}
  end

  @impl true
  def handle_info({:load, year, qtr}, socket) do
    url = "https://www.sec.gov/Archives/edgar/full-index/#{year}/#{qtr}/xbrl.idx"
    indices = SecFilings.EdgarClient.get_index(url)

    indices
    |> Flow.from_enumerable()
    |> Flow.filter(fn item -> not is_nil(item) end)
    |> Flow.map(fn item ->
      SecFilings.Raw.create_index(item)
    end)
    |> Enum.to_list()

    new_progress = [url] ++ socket.assigns.progress

    num_rows = SecFilings.Repo.aggregate(SecFilings.Raw.Index, :count, :id)
    {:noreply, assign(socket, progress: new_progress, num_rows: num_rows)}
  end
end
