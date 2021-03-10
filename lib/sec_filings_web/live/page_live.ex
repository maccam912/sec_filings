defmodule SecFilingsWeb.PageLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    companies =
      SecFilings.Repo.all(
        from c in SecFilings.Raw.Index,
          where: c.form_type in ["10-K", "10-Q"],
          order_by: [desc: :date_filed],
          limit: 10
      )

    {:ok, assign(socket, tables: companies)}
  end
end
