import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/raffle_bot start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :raffle_bot, RaffleBotWeb.Endpoint, server: true
end

config :raffle_bot, RaffleBotWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /data/raffle.db
      """

  config :raffle_bot, RaffleBot.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :raffle_bot, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :raffle_bot, RaffleBotWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Bind to IPv4 0.0.0.0 on all interfaces for Fly.io
      ip: {0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT", "8080"))
    ],
    secret_key_base: secret_key_base
end

# Configure Nostrum
config :nostrum,
  token: System.get_env("DISCORD_BOT_TOKEN"),
  num_shards: 1
