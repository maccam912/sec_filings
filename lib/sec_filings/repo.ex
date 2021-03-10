defmodule SecFilings.Repo do
  use Ecto.Repo,
    otp_app: :sec_filings,
    adapter: Ecto.Adapters.MyXQL
end
