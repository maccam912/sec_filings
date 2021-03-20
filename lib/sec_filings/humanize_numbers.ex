defmodule SecFilings.HumanizeNumbers do
  def humanize(n) when n < 0 do
    "-#{humanize(-1 * n)}"
  end

  def humanize(n) when n < 1.0e3 do
    "#{n}"
  end

  def humanize(n) when 1.0e3 <= n and n < 1.0e6 do
    "#{Float.round(n / 1.0e3, 1)} Thousand"
  end

  def humanize(n) when 1.0e6 <= n and n < 1.0e9 do
    "#{Float.round(n / 1.0e6, 1)} Million"
  end

  def humanize(n) when 1.0e9 <= n and n < 1.0e12 do
    "#{Float.round(n / 1.0e9, 1)} Billion"
  end

  def humanize(n) when 1.0e12 <= n and n < 1.0e15 do
    "#{Float.round(n / 1.0e12, 1)} Trillion"
  end

  def humanize(n) when 1.0e15 <= n and n < 1.0e18 do
    "#{Float.round(n / 1.0e15, 1)} Quadrillion"
  end

  def humanize(n) when 1.0e18 <= n and n < 1.0e21 do
    "#{Float.round(n / 1.0e18, 1)} Quintillion"
  end

  def repr(%{"instant" => dt}) do
    "#{dt}"
  end

  def repr(%{"startDate" => start_dt, "endDate" => end_dt}) do
    "#{start_dt} to #{end_dt}"
  end
end
