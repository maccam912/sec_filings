defmodule SecFilings.ParserWorker do
  import Ecto.Query, warn: false
  use GenServer
  alias SecFilings.Repo

  def get_unprocessed_documents() do
    get_unprocessed_documents(1_000_000)
  end

  def get_unprocessed_documents(n) do
    SecFilings.Repo.all(
      from i in SecFilings.Raw.Index,
        select: i,
        left_join: p in SecFilings.ParsedDocument,
        on: i.id == p.index_id,
        where: is_nil(p.index_id),
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
      catch
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
    context_multi_task =
      Task.async(fn ->
        process_document_context_changesets(document_string, index_id)
        |> Flow.from_enumerable(stages: 4, min_demand: 4, max_demand: 8)
        |> Flow.filter(fn changeset -> changeset.valid? end)
        |> Enum.reduce(%Ecto.Multi{}, fn item, acc ->
          Ecto.Multi.insert(acc, item, item, on_conflict: :nothing)
        end)
      end)

    context_multi = Task.await(context_multi_task, 5000)

    {:ok, _} = SecFilings.Repo.transaction(context_multi, timeout: 60000)

    # Contexts need to exist in db before we do tags
    tag_multi_task =
      Task.async(fn ->
        process_document_tag_changesets(document_string, index_id)
        |> Flow.from_enumerable(stages: 4, min_demand: 4, max_demand: 8)
        |> Flow.filter(fn changeset -> changeset.valid? end)
        |> Enum.reduce(%Ecto.Multi{}, fn item, acc ->
          Ecto.Multi.insert(acc, item, item, on_conflict: :nothing)
        end)
      end)

    tag_multi = Task.await(tag_multi_task, 5000)

    {:ok, _} = SecFilings.Repo.transaction(tag_multi, timeout: 60000)

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
    IO.puts("Done with batch")
  end

  def task_process_n(n, pid) do
    process_n(n)
    IO.puts("Sending update message")
    send(pid, :update)
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(state) do
    Process.send_after(__MODULE__, :update, 1000 * 10)
    {:ok, state}
  end

  @impl true
  def handle_info({:doc, item}, state) do
    [_, _, cik, adsh, _] = String.split(item.filename, ["/", "."])
    doc = SecFilings.DocumentGetter.get_doc(cik, adsh)
    process_document(doc, cik, adsh)
    {:noreply, state}
  end

  @impl true
  def handle_info(:update, state) do
    # {:ok, pid} = Task.start_link(fn -> task_process_n(100, self()) end)
    get_unprocessed_documents(100)
    |> Enum.map(fn item ->
      send(self(), {:doc, item})
    end)

    send(self(), :update)
    {:noreply, state}
  end

  def kill() do
    GenServer.cast(__MODULE__, :kill)
  end

  @impl true
  def handle_cast(:kill, state) do
    Process.exit(state, :kill)

    {:stop, :oom, state}
  end
end
