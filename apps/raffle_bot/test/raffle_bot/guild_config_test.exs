defmodule RaffleBot.GuildConfigTest do
  use RaffleBot.DataCase

  alias RaffleBot.GuildConfig

  describe "guild_configurations" do
    alias RaffleBot.GuildConfig.GuildConfiguration

    import RaffleBot.GuildConfigFixtures

    @invalid_attrs %{guild_id: nil, admin_channel_id: nil, user_channel_id: nil, bot_boss_role_id: nil}

    test "list_guild_configs/0 returns all guild configurations" do
      guild_config = guild_config_fixture()
      assert GuildConfig.list_guild_configs() == [guild_config]
    end

    test "get_guild_config!/1 returns the guild configuration with given id" do
      guild_config = guild_config_fixture()
      assert GuildConfig.get_guild_config!(guild_config.id) == guild_config
    end

    test "get_guild_config_by_guild_id/1 returns the guild configuration for given guild_id" do
      guild_config = guild_config_fixture(%{guild_id: "999999999999999999"})
      assert GuildConfig.get_guild_config_by_guild_id("999999999999999999") == guild_config
    end

    test "get_guild_config_by_guild_id/1 returns nil when guild_id not found" do
      assert GuildConfig.get_guild_config_by_guild_id("nonexistent") == nil
    end

    test "create_guild_config/1 with valid data creates a guild configuration" do
      valid_attrs = %{
        guild_id: "123456789012345678",
        admin_channel_id: "111111111111111111",
        user_channel_id: "222222222222222222",
        bot_boss_role_id: "333333333333333333"
      }

      assert {:ok, %GuildConfiguration{} = guild_config} = GuildConfig.create_guild_config(valid_attrs)
      assert guild_config.guild_id == "123456789012345678"
      assert guild_config.admin_channel_id == "111111111111111111"
      assert guild_config.user_channel_id == "222222222222222222"
      assert guild_config.bot_boss_role_id == "333333333333333333"
    end

    test "create_guild_config/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GuildConfig.create_guild_config(@invalid_attrs)
    end

    test "create_guild_config/1 with duplicate guild_id returns error" do
      guild_config_fixture(%{guild_id: "duplicate_guild"})

      attrs = %{
        guild_id: "duplicate_guild",
        admin_channel_id: "444444444444444444",
        user_channel_id: "555555555555555555",
        bot_boss_role_id: "666666666666666666"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = GuildConfig.create_guild_config(attrs)
      assert "has already been taken" in errors_on(changeset).guild_id
    end

    test "update_guild_config/2 with valid data updates the guild configuration" do
      guild_config = guild_config_fixture()
      update_attrs = %{
        admin_channel_id: "777777777777777777",
        user_channel_id: "888888888888888888",
        bot_boss_role_id: "999999999999999999"
      }

      assert {:ok, %GuildConfiguration{} = guild_config} =
        GuildConfig.update_guild_config(guild_config, update_attrs)
      assert guild_config.admin_channel_id == "777777777777777777"
      assert guild_config.user_channel_id == "888888888888888888"
      assert guild_config.bot_boss_role_id == "999999999999999999"
    end

    test "update_guild_config/2 with invalid data returns error changeset" do
      guild_config = guild_config_fixture()
      assert {:error, %Ecto.Changeset{}} =
        GuildConfig.update_guild_config(guild_config, @invalid_attrs)
      assert guild_config == GuildConfig.get_guild_config!(guild_config.id)
    end

    test "delete_guild_config/1 deletes the guild configuration" do
      guild_config = guild_config_fixture()
      assert {:ok, %GuildConfiguration{}} = GuildConfig.delete_guild_config(guild_config)
      assert_raise Ecto.NoResultsError, fn -> GuildConfig.get_guild_config!(guild_config.id) end
    end

    test "change_guild_config/1 returns a guild configuration changeset" do
      guild_config = guild_config_fixture()
      assert %Ecto.Changeset{} = GuildConfig.change_guild_config(guild_config)
    end

    test "upsert_guild_config/1 creates new configuration when guild_id doesn't exist" do
      attrs = %{
        guild_id: "new_guild_123",
        admin_channel_id: "111111111111111111",
        user_channel_id: "222222222222222222",
        bot_boss_role_id: "333333333333333333"
      }

      assert {:ok, %GuildConfiguration{} = guild_config} = GuildConfig.upsert_guild_config(attrs)
      assert guild_config.guild_id == "new_guild_123"
      assert guild_config.admin_channel_id == "111111111111111111"
    end

    test "upsert_guild_config/1 updates existing configuration when guild_id exists" do
      existing = guild_config_fixture(%{guild_id: "existing_guild"})

      attrs = %{
        guild_id: "existing_guild",
        admin_channel_id: "999999999999999999",
        user_channel_id: "888888888888888888",
        bot_boss_role_id: "777777777777777777"
      }

      assert {:ok, %GuildConfiguration{} = guild_config} = GuildConfig.upsert_guild_config(attrs)
      assert guild_config.id == existing.id
      assert guild_config.guild_id == "existing_guild"
      assert guild_config.admin_channel_id == "999999999999999999"
    end
  end

  describe "helper functions" do
    import RaffleBot.GuildConfigFixtures

    test "has_guild_config?/1 returns true when guild has configuration" do
      guild_config_fixture(%{guild_id: "configured_guild"})
      assert GuildConfig.has_guild_config?("configured_guild") == true
    end

    test "has_guild_config?/1 returns false when guild has no configuration" do
      assert GuildConfig.has_guild_config?("unconfigured_guild") == false
    end
  end
end
