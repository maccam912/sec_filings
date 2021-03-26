defmodule SecFilings.DocumentGetterTest do
  use SecFilings.DataCase
  alias SecFilings.DocumentParser

  @tag_string "<us-gaap:Revenues\n      contextRef=\"i0d883c24c5684358a8d9bd5cb272e84f_D20200101-20201231\"\n      decimals=\"-3\"\n      id=\"id3VybDovL2RvY3MudjEvZG9jOmNhMmU5ZDYwMjUzMTRlOGNhY2I3YjM2MWJkMzFiNGQ0L3NlYzpjYTJlOWQ2MDI1MzE0ZThjYWNiN2IzNjFiZDMxYjRkNF8xMDkvZnJhZzpiMDkyYzU0NmEyYjg0NTkzODU4ZmE5Yzk4NzVmOGU2My90YWJsZTo4ODZkY2UxOWQ2YTc0ODc4YWU1ZTg3N2Q4NmNhZjc0YS90YWJsZXJhbmdlOjg4NmRjZTE5ZDZhNzQ4NzhhZTVlODc3ZDg2Y2FmNzRhXzItMi0xLTEtMA_d7b62e19-a4f1-4d83-bc99-5d9abcef1107\"\n      unitRef=\"usd\">24996056000</us-gaap:Revenues>"
  @period_string "<xbrli:context id=\"i0d883c24c5684358a8d9bd5cb272e84f_D20200101-20201231\"><xbrli:entity><xbrli:identifier scheme=\"http://www.sec.gov/CIK\">0001065280</xbrli:identifier></xbrli:entity><xbrli:period><xbrli:startDate>2020-01-01</xbrli:startDate><xbrli:endDate>2020-12-31</xbrli:endDate></xbrli:period></xbrli:context>"
  @instant_string "<xbrli:context id=\"i0928d8abb9db47fa82888c8c880c5282_I20191231\"><xbrli:entity><xbrli:identifier scheme=\"http://www.sec.gov/CIK\">0001065280</xbrli:identifier><xbrli:segment><xbrldi:explicitMember dimension=\"srt:StatementGeographicalAxis\">nflx:InternationalMember</xbrldi:explicitMember></xbrli:segment></xbrli:entity><xbrli:period><xbrli:instant>2019-12-31</xbrli:instant></xbrli:period></xbrli:context>"

  describe "DocumentParser" do
    def document_fixture() do
      File.read!("test/resources/nflx10k.txt")
    end

    test "get_tag_strings/1" do
      document = document_fixture()
      tag_strings = DocumentParser.get_tag_strings(document)
      assert length(tag_strings) > 0
      assert String.contains?(List.first(tag_strings), "<us-gaap:")
      assert @tag_string in tag_strings
    end

    test "get_context_strings/1 period" do
      document = document_fixture()
      context_strings = DocumentParser.get_context_strings(document)
      assert length(context_strings) > 0
      assert String.contains?(List.first(context_strings), "context")
      assert @period_string in context_strings
    end

    test "get_context_strings/1 instant" do
      document = document_fixture()
      context_strings = DocumentParser.get_context_strings(document)
      assert length(context_strings) > 0
      assert String.contains?(List.first(context_strings), "context")
      assert @instant_string in context_strings
    end

    test "parse_tag_string/1" do
      tag = DocumentParser.parse_tag_string(@tag_string)
      assert Map.keys(tag) == ["Revenues"]
      assert String.length(tag["Revenues"][:context]) > 0
      assert tag["Revenues"][:value] == 2.4996056e10
    end

    test "parse_context_string/1 period" do
      context = DocumentParser.parse_context_string(@period_string)
      assert Map.keys(context) == ["i0d883c24c5684358a8d9bd5cb272e84f_D20200101-20201231"]

      assert context["i0d883c24c5684358a8d9bd5cb272e84f_D20200101-20201231"][:start_date] ==
               ~D[2020-01-01]

      assert context["i0d883c24c5684358a8d9bd5cb272e84f_D20200101-20201231"][:end_date] ==
               ~D[2020-12-31]
    end

    test "parse_context_string/1 instant" do
      context = DocumentParser.parse_context_string(@instant_string)
      assert Map.keys(context) == ["i0928d8abb9db47fa82888c8c880c5282_I20191231"]
      assert context["i0928d8abb9db47fa82888c8c880c5282_I20191231"][:start_date] == ~D[2019-12-31]
      assert context["i0928d8abb9db47fa82888c8c880c5282_I20191231"][:end_date] == ~D[2019-12-31]
    end
  end
end
