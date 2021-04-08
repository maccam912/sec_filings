defmodule SecFilings.ParserWorker do
  import Ecto.Query, warn: false
  use GenServer
  alias SecFilings.Repo

  def get_unprocessed_documents() do
    q1 = from p in SecFilings.ParsedDocument, select: p.index_id
    SecFilings.Repo.all(from i in SecFilings.Raw.Index, where: i.id not in subquery(q1))
  end

  def get_unprocessed_documents(n) do
    q1 = from p in SecFilings.ParsedDocument, select: p.index_id

    SecFilings.Repo.all(
      from i in SecFilings.Raw.Index,
        where: i.id not in subquery(q1),
        order_by: fragment("RANDOM()"),
        limit: ^n
    )
  end

  def process_document_context_changesets(document_string, index_id) do
    SecFilings.DocumentParser.get_context_strings(document_string)
    |> Stream.map(&SecFilings.DocumentParser.parse_context_string/1)
    |> Stream.map(fn item ->
      [id] = Map.keys(item)
      sd = item[id][:start_date]
      ed = item[id][:end_date]

      SecFilings.Context.changeset(%SecFilings.Context{}, %{
        context_id: id,
        start_date: sd,
        end_date: ed,
        index_id: index_id
      })
    end)
  end

  def process_document_tag_changesets(document_string, index_id) do
    SecFilings.DocumentParser.get_tag_strings(document_string)
    |> Stream.map(fn tag_string ->
      try do
        SecFilings.DocumentParser.parse_tag_string(tag_string)
      rescue
        _ -> nil
      end
    end)
    |> Stream.filter(fn item -> !is_nil(item) end)
    |> Stream.map(fn item ->
      [tag] = Map.keys(item)
      context = item[tag][:context]
      value = item[tag][:value]

      context_id =
        Repo.one(
          from c in SecFilings.Context,
            where: c.context_id == ^context and c.index_id == ^index_id,
            select: c.id
        )

      SecFilings.Tag.changeset(%SecFilings.Tag{}, %{
        tag: tag,
        value: value,
        context_id: context_id
      })
    end)
  end

  def _process_document(document_string, index_id) do
    context_multi =
      process_document_context_changesets(document_string, index_id)
      |> Enum.filter(fn changeset -> changeset.valid? end)
      |> Enum.reduce(%Ecto.Multi{}, fn item, acc ->
        Ecto.Multi.insert(acc, item, item, on_conflict: :nothing)
      end)

    {:ok, _} = SecFilings.Repo.transaction(context_multi)

    # Contexts need to exist in db before we do tags
    tag_multi =
      process_document_tag_changesets(document_string, index_id)
      |> Enum.filter(fn changeset -> changeset.valid? end)
      |> Enum.reduce(%Ecto.Multi{}, fn item, acc ->
        Ecto.Multi.insert(acc, item, item, on_conflict: :nothing)
      end)

    {:ok, _} = SecFilings.Repo.transaction(tag_multi)

    SecFilings.ParsedDocument.changeset(%SecFilings.ParsedDocument{}, %{
      dt_processed: Date.utc_today(),
      status: true,
      index_id: index_id
    })
    |> Repo.insert()
  end

  def process_document(document_string, cik, adsh) do
    filename = SecFilings.Util.generate_filename(cik, adsh)

    index_id =
      Repo.one(from i in SecFilings.Raw.Index, where: i.filename == ^filename, select: i.id)

    try do
      _process_document(document_string, index_id)
    rescue
      _ ->
        SecFilings.ParsedDocument.changeset(%SecFilings.ParsedDocument{}, %{
          dt_processed: Date.utc_today(),
          status: false,
          index_id: index_id
        })
        |> Repo.insert()
    end
  end

  def process_batch(docs) do
    docs
    |> Flow.from_enumerable(stages: 16, min_demand: 16, max_demand: 32)
    |> Flow.map(fn index ->
      [_, _, cik, adsh, _] = String.split(index.filename, ["/", "."])
      {SecFilings.DocumentGetter.get_doc(cik, adsh), cik, adsh}
    end)
    |> Flow.map(fn {doc, cik, adsh} ->
      process_document(doc, cik, adsh)
    end)
    |> Flow.run()
  end

  def process_all() do
    process_batch(get_unprocessed_documents())
  end

  def process_n(n) do
    process_batch(get_unprocessed_documents(n))

    Process.send_after(__MODULE__, :update, 1000 * 30)
    IO.puts("Done with batch")
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(state) do
    Process.send_after(__MODULE__, :update, 1000 * 30)
    {:ok, state}
  end

  @impl true
  def handle_info(:update, _state) do
    {:ok, pid} = Task.start_link(fn -> process_n(100) end)
    {:noreply, pid}
  end

  # @impl true
  # def handle_info(:update, []) do
  #   unprocessed = get_unprocessed_documents(400)

  #   Process.send_after(__MODULE__, :update, 1000 * 3)
  #   {:noreply, unprocessed}
  # end

  # @impl true
  # def handle_info(:update, unprocessed) do
  #   [document | rest] = unprocessed

  #   [_, _, cik, adsh, _] = String.split(document.filename, ["/", "."])

  #   SecFilings.Util.generate_url(cik, adsh)
  #   |> SecFilings.DocumentGetter.get_doc()
  #   |> process_document(cik, adsh)

  #   Process.send_after(__MODULE__, :update, 1000 * 3)
  #   {:noreply, rest}
  # end

  def kill() do
    GenServer.cast(__MODULE__, :kill)
  end

  @impl true
  def handle_cast(:kill, state) do
    Process.exit(state, :kill)

    {:stop, :oom, state}
  end
end
