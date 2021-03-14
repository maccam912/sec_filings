use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :sec_filings, SecFilings.Repo,
  # username: "root",
  username: "postgres",
  password: "postgres",
  # password: System.get_env("DB_PASS"),
  database: "sec_filings_test#{System.get_env("MIX_TEST_PARTITION")}",
  # database: "sec-filings-db-test",
  hostname: "localhost",
  # hostname: "sec-filings-db.database.windows.net",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sec_filings, SecFilingsWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
