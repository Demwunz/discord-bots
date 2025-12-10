# This file is responsible for configuring your umbrella
# and all applications and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :raffle_bot,
  ecto_repos: [RaffleBot.Repo],
  adapter: Ecto.Adapters.SQLite3,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :raffle_bot, RaffleBotWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RaffleBotWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: RaffleBot.PubSub,
  live_view: [signing_salt: "your_signing_salt"]

# Configure logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
