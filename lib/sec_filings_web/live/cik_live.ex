defmodule SecFilingsWeb.CikLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(params, _session, socket) do
    companies =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"] and c.cik == ^Map.get(params, "cik"),
          order_by: [desc: :date_filed]
      )

    send(self(), :update)
    {:ok, assign(socket, params: params, tables: companies, debug: "")}
  end

  @impl true
  def handle_info(:update, state) do
    c1 = List.first(state.assigns.tables)
    IO.inspect(SecFilings.NumberExtractor.get_tags(c1.filename))
    {:noreply, assign(state, debug: "")}
  end
end
