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

  def report_title(table) do
    rows = Floki.find(table, "tr")
    first_row = List.first(rows)
    header_cells = Floki.find(first_row, "th")
    title = List.first(header_cells)
    String.trim(Floki.text(title))
  end

  def find_revenue(table) do
    IO.inspect(table)
    # Get rows with "revenue" in them
    possible_rows =
      Floki.find(table, "tr")
      |> Enum.filter(fn row ->
        String.contains?(String.downcase(Floki.text(row)), "revenue")
      end)

    # Top line is usually what we want here.
    row = List.first(possible_rows)

    # Most recent is usually left column. Excluding label, thats the second cell
    cell =
      Floki.find(row, "td")
      |> Enum.filter(fn cell ->
        Regex.match?(~r/.*[0-9]+.*/, Floki.text(cell))
      end)
      |> List.first()

    # Remove all $, (, ), and , to clean up number
    num_text =
      Floki.text(cell)
      |> String.replace(["$", "(", ")", ","], "")
      |> String.trim()

    {num, _} = Integer.parse(num_text)
    num
  end

  def get_scaling_factor(table) do
    title = String.downcase(report_title(table))
    [[_, scaling_word]] = Regex.scan(~r/\$ in ([a-z]*)/, title)

    cond do
      String.contains?(scaling_word, "thousand") -> 1000
      String.contains?(scaling_word, "million") -> 1_000_000
      true -> 1
    end
  end

  def parse_income_statement(table) do
    revenue = get_scaling_factor(table) * find_revenue(table)
    %{revenue: revenue}
  end

  def parse_single_document(doc) do
    {"document", [], [{"type", [], [type | [seq]]}]} = doc
    {"sequence", [], [seq_num, filename]} = seq
    {"filename", [], [filename, description]} = filename
    {description, doc} = parse_desc(description)

    type = String.trim(type)
    {seq_num, ""} = Integer.parse(String.trim(seq_num))
    filename = String.trim(filename)

    reports =
      Floki.find(doc, "table.report")
      |> Enum.filter(fn report ->
        String.contains?(String.downcase(report_title(report)), "consolidated")
      end)
      |> Enum.map(fn report ->
        norm_title = String.downcase(report_title(report))

        if !String.contains?(norm_title, "note") and String.contains?(norm_title, "consolidated") and
             String.contains?(norm_title, "statement") and
             String.contains?(norm_title, "operations") do
          # Income statement!
          parse_income_statement(report)
        else
          %{}
        end
      end)

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
    if Mix.env() in [:dev, :test] do
      download_documents(cik, adsh)
    else
      Cachex.get!(:filings_cache, {cik, adsh}) || download_documents(cik, adsh)
    end
  end
end
