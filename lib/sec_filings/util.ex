defmodule SecFilings.Util do
  @moduledoc """
  Any reused functions that are pretty general.
  """

  @doc """
  Given a cik and an adsh, generate the filename
  the sec has for this submission.
  """
  def generate_filename(cik, adsh) do
    "edgar/data/#{cik}/#{adsh}.txt"
  end

  @doc """
  Given a filename, append it to the base URL
  to get the URL that you can request the document
  from.
  """
  def generate_url(filename) do
    "https://www.sec.gov/Archives/#{filename}"
  end

  @doc """
  Just a tiny helper for a common operation of
  generating the filename, then the URL from
  that filename.
  """
  def generate_url(cik, adsh) do
    generate_filename(cik, adsh) |> generate_url()
  end
end
