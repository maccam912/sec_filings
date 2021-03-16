defmodule SecFilings.NumberExtractor do
  def parse_desc({"description", [], [desc_text, text]}) do
    {"text", [], doc} = text

    if length(doc) == 1 do
      {String.trim(desc_text), List.first(doc)}
    else
      {String.trim(desc_text), nil}
    end
  end

  def parse_desc({"text", [], doc}) do
    {nil, doc}
  end

  def parse_single_document(doc) do
    {"document", [], [{"type", [], [type | [seq]]}]} = doc
    {"sequence", [], [seq_num, filename]} = seq
    {"filename", [], [filename, description]} = filename
    {description, doc} = parse_desc(description)

    type = String.trim(type)
    {seq_num, ""} = Integer.parse(String.trim(seq_num))
    filename = String.trim(filename)
    reports = Floki.find(doc, "table.report")

    %{
      type: type,
      sequence_number: seq_num,
      filename: filename,
      description: description,
      reports: reports
    }
  end

  def gen_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  def gen_url(cik, adsh) do
    "https://www.sec.gov/Archives/#{gen_filename(cik, adsh)}"
  end

  def download_documents(cik, adsh) do
    url = gen_url(cik, adsh)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url)
    doc = Floki.parse_document!(body)

    docs =
      Floki.find(doc, "document")
      |> Enum.map(fn doc -> parse_single_document(doc) end)

    {:ok, true} = Cachex.put(:filings_cache, {cik, adsh}, docs)
    docs
  end

  def get_documents(cik, adsh) do
    Cachex.get!(:filings_cache, {cik, adsh}) || download_documents(cik, adsh)
  end
end
