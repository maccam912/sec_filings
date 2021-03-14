# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sec_filings,
  ecto_repos: [SecFilings.Repo]

# Configures the endpoint
config :sec_filings, SecFilingsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ltiKG16YOobeJ5LMRlQImi96NL7P9V3Ds5zNaDntVVMz4qXeeSBMjVdOtfaUengC",
  render_errors: [view: SecFilingsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: SecFilings.PubSub,
  live_view: [signing_salt: "urhe1RRF"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
