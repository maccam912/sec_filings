defmodule SecFilings.EdgarClient do
  import Ecto.Query, warn: false
  NimbleCSV.define(IndexParser, separator: "|", escape: "\"")

  def get_index(url) do
    {st, %HTTPoison.Response{body: body}} =
      HTTPoison.get(url, %{"User-Agent" => "githubcom-maccam912-sec_filings/1.0"},
        hackney: [:insecure, pool: :first_pool]
      )

    if st != :ok do
      [nil]
    else
      parse_task = Task.async(fn -> IndexParser.parse_string(body) end)
      {st, rows} = Task.yield(parse_task, 60000)

      if st != :ok do
        [nil]
      else
        rows
        |> Enum.filter(fn row -> length(row) == 5 end)
        |> Enum.filter(fn [cik, _, _, _, _] -> cik != "CIK" end)
        |> Enum.map(fn [cik, company_name, form_type, date_filed, filename] ->
          {cik_int, _} = Integer.parse(cik)
          {:ok, date_filed_dt} = Datix.Date.parse(date_filed, "%x")

          %{
            cik: cik_int,
            company_name: company_name,
            form_type: form_type,
            date_filed: date_filed_dt,
            filename: filename
          }
        end)
      end
    end
  end

  def extract_title_content_children(document) do
    {title, [], [content | children]} = document
    {title, content, children}
  end

  def get_financial_statements(filename) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.get(
        "https://www.sec.gov/Archives/#{filename}",
        %{"User-Agent" => "githubcom-maccam912-sec_filings/1.0"},
        hackney: [:insecure, pool: :first_pool]
      )

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

      %{
        type: String.trim(type_text),
        sequence: String.trim(seq_text),
        filename: String.trim(fname_text),
        description: String.trim(desc_text),
        content: Floki.raw_html(report)
      }
    end)
  end
end
