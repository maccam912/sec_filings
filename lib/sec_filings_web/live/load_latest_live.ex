defmodule SecFilingsWeb.LoadLatestLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    send(self(), :update)
    {:ok, assign(socket, status: "Updating...")}
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

    {:noreply, assign(state, status: "Updated!")}
  end
end
