defmodule SecFilings.ParserWorker do
  import Ecto.Query, warn: false
  use GenServer
  alias SecFilings.Repo

  Process.flag(:max_heap_size, 400_000_000)

  def get_unprocessed_documents() do
    get_unprocessed_documents(1_000_000)
  end

  def get_unprocessed_documents(n) do
    SecFilings.Repo.all(
      from i in SecFilings.Raw.Index,
        where: i.status == -1,
        order_by: [desc: :date_filed],
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
    |> Stream.filter(fn item -> length(Map.keys(item)) > 0 end)
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

  def process_document(document_string, cik, adsh) do
    filename = SecFilings.Util.generate_filename(cik, adsh)
    index = Repo.one(from i in SecFilings.Raw.Index, where: i.filename == ^filename)

    context_multi_task =
      Task.async(fn ->
        valid_changesets =
          process_document_context_changesets(document_string, index.id)
          |> Flow.from_enumerable(stages: 4, min_demand: 4, max_demand: 8)
          |> Flow.filter(fn item -> item.valid? end)
          |> Enum.reduce(%Ecto.Multi{}, fn item, acc ->
            Ecto.Multi.insert(acc, UUID.uuid4(), item, on_conflict: :nothing)
          end)

        if length(valid_changesets.operations) == 0 do
          throw(:empty_context_changeset)
        end

        valid_changesets
      end)

    {:ok, context_multi} = Task.yield(context_multi_task, 5000)
    {:ok, _} = SecFilings.Repo.transaction(context_multi, timeout: 60000)

    # Contexts need to exist in db before we do tags
    tag_multi_task =
      Task.async(fn ->
        valid_changesets =
          process_document_tag_changesets(document_string, index.id)
          |> Flow.from_enumerable(stages: 4, min_demand: 4, max_demand: 8)
          |> Flow.filter(fn item -> item.valid? end)
          |> Enum.reduce(%Ecto.Multi{}, fn item, acc ->
            Ecto.Multi.insert(acc, UUID.uuid4(), item, on_conflict: :nothing)
          end)

        if length(valid_changesets.operations) == 0 do
          throw(:empty_tag_changeset)
        end

        valid_changesets
      end)

    {:ok, tag_multi} = Task.yield(tag_multi_task, 5000)
    {:ok, _} = SecFilings.Repo.transaction(tag_multi, timeout: 60000)

    SecFilings.Raw.Index.changeset(index, %{
      status: 1
    })
    |> Repo.update()
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(state) do
    Task.Supervisor.start_link(name: :task_supervisor)
    Process.send_after(__MODULE__, :update, 10)
    {:ok, state}
  end

  def process_item(item) do
    IO.puts("Starting #{item.filename}")

    index = Repo.one(from i in SecFilings.Raw.Index, where: i.filename == ^item.filename)

    SecFilings.Raw.Index.changeset(index, %{
      status: 0
    })
    |> Repo.update()

    t =
      Task.Supervisor.async_nolink(:task_supervisor, fn ->
        [_, _, cik, adsh, _] = String.split(item.filename, ["/", "."])
        doc = SecFilings.DocumentGetter.get_doc(cik, adsh)

        if not is_nil(doc) do
          process_document(doc, cik, adsh)
        end
      end)

    case Task.yield(t, 120_000) do
      {:ok, _} ->
        SecFilings.Raw.Index.changeset(index, %{
          status: 1
        })
        |> Repo.update()

      {:exit, {{:nocatch, :empty_context_changeset}, _}} ->
        SecFilings.Raw.Index.changeset(index, %{
          status: 2
        })
        |> Repo.update()

      {:exit, {{:nocatch, :empty_tag_changeset}, _}} ->
        SecFilings.Raw.Index.changeset(index, %{
          status: 3
        })
        |> Repo.update()

      _ ->
        SecFilings.Raw.Index.changeset(index, %{
          status: -99
        })
        |> Repo.update()
    end
  end

  @impl true
  def handle_info({:docs, items}, state) do
    items
    |> Flow.from_enumerable(stages: 16, min_demand: 16, max_demand: 32)
    |> Flow.map(fn item -> process_item(item) end)
    |> Flow.run()

    {:noreply, state}
  end

  @impl true
  def handle_info(:update, state) do
    # Before we start, check for any that are still status 0 (running)
    # Set them to 2, since they obviously never finished running
    Repo.all(from i in SecFilings.Raw.Index, where: i.status == 0)
    |> Enum.map(fn item ->
      SecFilings.Raw.Index.changeset(item, %{status: -2})
      |> Repo.update()
    end)

    send(self(), {:docs, get_unprocessed_documents(64)})

    send(self(), :update)
    {:noreply, state}
  end
end
