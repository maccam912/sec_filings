defmodule SecFilings.ParsecTest do
  use SecFilings.DataCase

  @str1 "<us-gaap:AllocatedShareBasedCompensationExpense contextRef=\"FD2018Q3YTD_us-gaap_IncomeStatementLocationAxis_us-gaap_ResearchAndDevelopmentExpenseMember\" decimals=\"-6\" id=\"Fact-B4ABDF8F1C2852329EA180898350B12B\" unitRef=\"usd\">1987000000</us-gaap:AllocatedShareBasedCompensationExpense>"
  @str2 "<us-gaap:AvailableForSaleSecurities contextRef=\"FI2017Q4_us-gaap_FairValueByFairValueHierarchyLevelAxis_us-gaap_FairValueInputsLevel2Member_us-gaap_InvestmentTypeAxis_us-gaap_ForeignGovernmentDebtSecuritiesMember\" decimals=\"-6\" id=\"Fact-59E6FEFFC2A85938B084733780D466A7\" unitRef=\"usd\">8000000000</us-gaap:AvailableForSaleSecurities>"

  test "test parser" do
    parsed_1 = IO.inspect(SecFilings.TagParser.parse(@str1))
    parsed_2 = IO.inspect(SecFilings.TagParser.parse(@str2))
    assert true
  end
end
