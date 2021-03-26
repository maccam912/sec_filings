defmodule SecFilings.ParserWorker do
  import Ecto.Query, warn: false
  alias SecFilings.Repo

  def get_unprocessed_documents() do
    Repo.all(from d in SecFilings.Raw.Index, preload: [:parsed_documents])
    |> Enum.filter(fn item ->
      is_nil(item.parsed_documents)
    end)
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

      contexts_id =
        Repo.one(
          from c in SecFilings.Context,
            where: c.context_id == ^context and c.index_id == ^index_id,
            select: c.id
        )

      SecFilings.Tag.changeset(%SecFilings.Tag{}, %{
        tag: tag,
        value: value,
        contexts_id: contexts_id
      })
    end)
    |> Stream.map(fn changeset ->
      Repo.insert(changeset)
    end)
    |> Stream.run()
  end

  def process_document(document_string, cik, adsh) do
    IO.puts("Processing context for #{adsh}")
    filename = SecFilings.Util.generate_filename(cik, adsh)

    index_id =
      Repo.one(from i in SecFilings.Raw.Index, where: i.filename == ^filename, select: i.id)

    process_document_contexts(document_string, index_id)
    IO.puts("Processing tags for #{adsh}")
    # Contexts need to exist in db before we do tags
    process_document_tags(document_string, index_id)

    SecFilings.ParsedDocument.changeset(%SecFilings.ParsedDocument{}, %{
      dt_processed: Date.utc_today(),
      index_id: index_id
    })
    |> Repo.insert()

    IO.puts("Done with #{adsh}")
  end

  def process_all() do
    get_unprocessed_documents()
    |> Stream.map(fn index ->
      [_, _, cik, adsh, _] = String.split(index.filename, ["/", "."])

      SecFilings.Util.generate_url(cik, adsh)
      |> SecFilings.DocumentGetter.get_doc()
      |> process_document(cik, adsh)
    end)
    |> Stream.run()
  end
end
