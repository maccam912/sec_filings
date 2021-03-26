defmodule SecFilingsWeb.TagsLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false
  require IEx

  @impl true
  def mount(params, _session, socket) do
    adsh = Map.get(params, "adsh")
    cik = Map.get(params, "cik")

    filename = SecFilings.Util.generate_filename(cik, adsh)

    index_id =
      SecFilings.Repo.one(
        from i in SecFilings.Raw.Index, where: i.filename == ^filename, select: i.id
      )

    tags =
      SecFilings.Repo.all(
        from c in SecFilings.Context, where: c.index_id == ^index_id, preload: [:tags]
      )
      |> Enum.flat_map(fn context ->
        context.tags
        |> Enum.map(fn tag ->
          {tag, context.start_date, context.end_date}
        end)
      end)
      |> Enum.map(fn {tag, sd, ed} ->
        v = %{"value" => tag.value, "period" => %{start_date: sd, end_date: ed}}
        {tag.tag, v}
      end)

    {:ok,
     assign(socket,
       tags: tags,
       adsh: adsh,
       cik: cik,
       query: ""
     )}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, assign(socket, query: query)}
  end
end
