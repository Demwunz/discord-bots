defmodule RaffleBot.GuildConfigFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaffleBot.GuildConfig` context.
  """

  @doc """
  Generate a guild configuration.
  """
  def guild_config_fixture(attrs \\ %{}) do
    {:ok, guild_config} =
      attrs
      |> Enum.into(%{
        guild_id: "123456789012345678",
        admin_channel_id: "111111111111111111",
        user_channel_id: "222222222222222222",
        bot_boss_role_id: "333333333333333333"
      })
      |> RaffleBot.GuildConfig.create_guild_config()

    guild_config
  end
end
