defmodule SecFilings.TagParser do
  import NimbleParsec

  # From https://github.com/dashbitco/nimble_parsec/blob/master/examples/simple_xml.exs

  tag = ascii_string([?a..?z, ?A..?Z], min: 1)

  attr =
    ignore(string(" "))
    |> ascii_string([?a..?z, ?A..?Z], min: 1)
    |> concat(string("="))
    |> ascii_string([not: ?\s], min: 1)

  text = ascii_string([not: ?>], min: 1)

  opening_tag =
    ignore(string("<us-gaap:"))
    |> concat(tag)
    |> repeat(
      lookahead_not(ascii_char([?>]))
      |> choice([
        attr,
        utf8_char([])
      ])
    )
    |> ignore(string(">"))

  closing_tag = ignore(string("</us-gaap:")) |> concat(tag) |> ignore(string(">"))

  defcombinatorp(
    :node,
    opening_tag
    |> repeat(lookahead_not(string("</")) |> choice([parsec(:node), text]))
    |> wrap()
    |> concat(closing_tag)
  )

  defparsec(:parse, parsec(:node) |> eos())
end
