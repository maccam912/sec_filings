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
      from i in SecFilings.Raw.Index, where: i.id not in subquery(q1), limit: ^n
    )
  end

  def process_document_contexts(document_string, index_id) do
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
    |> Stream.map(fn changeset ->
      Repo.insert(changeset)
    end)
    |> Stream.run()
  end

  def process_document_tags(document_string, index_id) do
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
    |> Stream.map(fn changeset ->
      Repo.insert(changeset)
    end)
    |> Stream.run()
  end

  def _process_document(document_string, index_id) do
    process_document_contexts(document_string, index_id)
    # Contexts need to exist in db before we do tags
    process_document_tags(document_string, index_id)

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
    total = length(docs)

    docs
    |> Stream.map(fn index ->
      [_, _, cik, adsh, _] = String.split(index.filename, ["/", "."])

      SecFilings.Util.generate_url(cik, adsh)
      |> SecFilings.DocumentGetter.get_doc()
      |> process_document(cik, adsh)
    end)
    |> Tqdm.tqdm(total: total)
    |> Stream.run()
  end

  def process_all() do
    process_batch(get_unprocessed_documents())
  end

  def process_n(n) do
    process_batch(get_unprocessed_documents(n))
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
  def handle_info(:update, []) do
    process_n(400)
    Process.send_after(__MODULE__, :update, 1000 * 3)
    {:noreply, []}
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
end
