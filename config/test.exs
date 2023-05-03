import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :cal, Cal.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cal_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cal, CalWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "yLMEfCUI5IRV2PUSj2RXA1WCSuLc+n+cl+ZnmPOFmzZDuIfaKcJDVIVAq2QzEPGN",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Google Auth test configs
config :elixir_auth_google,
  client_id: "631770888008-6n0oruvsm16kbkqg6u76p5cv5kfkcekt.apps.googleusercontent.com",
  client_secret: "MHxv6-RGF5nheXnxh1b0LNDq",
  httpoison_mock: true
