defmodule SecFilingsWeb.PageLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    companies =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"] and c.status == 1,
          order_by: [desc: :date_filed, asc: :company_name],
          limit: 300
      )

    {:ok, assign(socket, tables: companies, query: "")}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    companies =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"] and ilike(c.company_name, ^"%#{query}%"),
          order_by: [desc: :date_filed, asc: :company_name],
          limit: 100
      )

    {:noreply, assign(socket, tables: companies, query: query)}
  end
end
