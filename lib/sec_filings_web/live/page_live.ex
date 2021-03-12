defmodule SecFilingsWeb.PageLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    companies =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q", "8-K"],
          order_by: [desc: :date_filed],
          limit: 100
      )

    {:ok, assign(socket, tables: companies, query: "")}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    companies =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q", "8-K"] and like(c.company_name, ^"%#{query}%"),
          order_by: [desc: :date_filed],
          limit: 1000
      )

    {:noreply, assign(socket, tables: companies, query: query)}
  end
end
