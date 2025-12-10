import Config

# Configure your database for SQLite
config :raffle_bot, RaffleBot.Repo,
  database: Path.expand("../raffle_bot_test#{System.get_env("MIX_TEST_PARTITION")}.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test
config :raffle_bot, RaffleBotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "UbnboEzmKbXOUtmDjbUpyfhZms2WxZPh4PlbBFb0nIZN/OWsurbteVVBmnilB5d9",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes
config :phoenix,
  sort_verified_routes_query_params: true

# Configure Nostrum for test environment
config :nostrum,
  token: "test_token",
  num_shards: 1

# Disable Discord processes in test
config :raffle_bot,
  start_discord: false
