defmodule SecFilings.NumberExtractor do
  def get_tags(filename) do
    url = "https://www.sec.gov/Archives/#{filename}"
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url)
    numbers = Regex.scan(~r/<ix:nonFraction[^>]*>[^<]*<\/ix:nonFraction>/, body)
    numbers
  end
end
