defmodule SecFilings.EdgarClient do
  import Ecto.Query, warn: false
  NimbleCSV.define(IndexParser, separator: "|", escape: "\"")

  def get_index(url) do
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, %{}, hackney: [:insecure])
    rows = IndexParser.parse_string(body)
    rows
    |> Enum.filter(fn row -> length(row) == 5 end)
    |> Enum.filter(fn [cik, _, _, _, _] -> cik != "CIK" end)
    |> Enum.map(fn [cik, company_name, form_type, date_filed, filename] ->
      {cik_int, _} = Integer.parse(cik)
      {:ok, date_filed_dt} = Datix.Date.parse(date_filed, "%x")
      %{cik: cik_int, company_name: company_name, form_type: form_type, date_filed: date_filed_dt, filename: filename}
    end)
  end

  def extract_title_content_children(document) do
    {title, [], [content | children]} = document
    {title, content, children}
  end

  def get_financial_statements(filename) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get("https://www.sec.gov/Archives/#{filename}", %{}, hackney: [:insecure])
    document = Floki.parse_document!(body)

    Floki.find(document, "document")
    |> Enum.map(fn doc ->
      {"document", [], [type | _]} = doc
      {_, type_text, [sequence | _]} = extract_title_content_children(type)
      {_, seq_text, [filename | _]} = extract_title_content_children(sequence)
      {_, fname_text, [description | _]} = extract_title_content_children(filename)
      {_, desc_text, [text | _]} = extract_title_content_children(description)
      {_, text_text, _} = extract_title_content_children(text)

      report = Floki.find(text_text, "table.report")
      %{type: String.trim(type_text), sequence: String.trim(seq_text), filename: String.trim(fname_text), description: String.trim(desc_text), content: Floki.raw_html(report)}
    end)

  end

  def old_get_financial_statements(filename) do
    parts = String.split(filename, ["/"])
    cik = Enum.at(parts, 2)
    adsh_txt = Enum.at(parts, 3)
    adsh = String.split(adsh_txt, ["."])
    |> List.first()
    #"https://www.sec.gov/cgi-bin/viewer?action=view&cik=#{cik}&accession_number=#{adsh}&xbrl_type=v"
    adsh_fixed = String.replace(adsh, "-", "")
    1..10
      |> Enum.map(fn num -> "https://www.sec.gov/Archives/edgar/data/#{cik}/#{adsh_fixed}/R#{num}.htm" end)
      |> Flow.from_enumerable()
      |> Flow.map(fn url ->
        HTTPoison.get(url)
      end)
      |> Flow.filter(fn {st, response} -> st == :ok and response.status_code == 200 end)
      |> Flow.map(fn {:ok, %HTTPoison.Response{body: body}} -> Floki.parse_document(body) end)
      |> Enum.to_list()
  end
end
