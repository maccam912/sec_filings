defmodule SecFilings.TagExtractorWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def load_cik(cik) do
    GenServer.cast(__MODULE__, {:insert, cik})
    :ok
  end

  def insert(cik, adsh) do
    GenServer.cast(__MODULE__, {:insert, {cik, adsh}})
    :ok
  end

  @impl true
  def init(opt) do
    {:ok, opt}
  end

  @impl true
  def handle_cast({:insert, {cik, adsh}}, state) do
    IO.puts("Starting CIK #{cik}")
    SecFilings.TagExtractor.insert_tags(cik, adsh)
    IO.puts("Done with CIK #{cik}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:insert, cik}, state) do
    IO.puts("Starting CIK #{cik}")

    SecFilings.TagExtractor.get_filenames_for_cik(cik)
    |> Enum.map(fn filename -> SecFilings.TagExtractor.get_cik_adsh(filename) end)
    |> Enum.map(fn {cik, adsh} ->
      insert(cik, adsh)
    end)

    IO.puts("Done with CIK #{cik}")
    {:noreply, state}
  end
end
