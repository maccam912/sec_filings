defmodule SecFilings.MemMon do
  use GenServer

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__)
  end

  def init(_init) do
    send(self(), :check)
    {:ok, []}
  end

  def handle_info(:check, state) do
    if :erlang.memory()[:total] > 1_250_000_000 do
      SecFilings.ParserWorker.kill()
    end

    Process.send_after(self(), :check, 10000)
    {:noreply, state}
  end
end
