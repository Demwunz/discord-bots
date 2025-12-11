defmodule DiscordBotUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        raffle_bot: [
          applications: [
            raffle_bot: :permanent
          ]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:nostrum, "~> 0.7", override: true},
      {:ecto_sqlite3, "~> 0.10", override: true},
      {:jason, "~> 1.4", override: true},
      {:swoosh, "~> 1.5", override: true}
    ]
  end
end
