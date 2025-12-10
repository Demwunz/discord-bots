defmodule RaffleBot.Discord.ApiConsumer do
  @moduledoc """
  A module to be used by modules that need to make Discord API calls.
  It injects the `Api` alias and a function to get the configured API module.
  """

  defmacro __using__(_opts) do
    quote do
      alias RaffleBot.Discord.Api

      defp discord_api do
        Application.get_env(:raffle_bot, :discord_api)
      end
    end
  end
end
