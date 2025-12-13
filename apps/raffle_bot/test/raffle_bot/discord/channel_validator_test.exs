defmodule RaffleBot.Discord.ChannelValidatorTest do
  use RaffleBot.DataCase

  alias RaffleBot.Discord.ChannelValidator
  import RaffleBot.GuildConfigFixtures

  describe "validate_channel/2 with :admin command type" do
    test "returns {:ok, nil} when command is in correct admin channel" do
      guild_config_fixture(%{
        guild_id: "test_guild",
        admin_channel_id: "admin_channel_123"
      })

      interaction = %{
        guild_id: "test_guild",
        channel_id: "admin_channel_123"
      }

      assert {:ok, nil} = ChannelValidator.validate_channel(interaction, :admin)
    end

    test "returns {:ok, warning} when admin command used in wrong channel" do
      guild_config_fixture(%{
        guild_id: "test_guild",
        admin_channel_id: "admin_channel_123",
        user_channel_id: "user_channel_456"
      })

      interaction = %{
        guild_id: "test_guild",
        channel_id: "user_channel_456"
      }

      assert {:ok, warning} = ChannelValidator.validate_channel(interaction, :admin)
      assert warning =~ "admin"
      assert warning =~ "<#admin_channel_123>"
    end

    test "returns {:ok, nil} when guild is not configured (allows command)" do
      interaction = %{
        guild_id: "unconfigured_guild",
        channel_id: "any_channel"
      }

      assert {:ok, nil} = ChannelValidator.validate_channel(interaction, :admin)
    end
  end

  describe "validate_channel/2 with :user command type" do
    test "returns {:ok, nil} when command is in correct user channel" do
      guild_config_fixture(%{
        guild_id: "test_guild",
        user_channel_id: "user_channel_456"
      })

      interaction = %{
        guild_id: "test_guild",
        channel_id: "user_channel_456"
      }

      assert {:ok, nil} = ChannelValidator.validate_channel(interaction, :user)
    end

    test "returns {:ok, warning} when user command used in wrong channel" do
      guild_config_fixture(%{
        guild_id: "test_guild",
        admin_channel_id: "admin_channel_123",
        user_channel_id: "user_channel_456"
      })

      interaction = %{
        guild_id: "test_guild",
        channel_id: "admin_channel_123"
      }

      assert {:ok, warning} = ChannelValidator.validate_channel(interaction, :user)
      assert warning =~ "user"
      assert warning =~ "<#user_channel_456>"
    end

    test "returns {:ok, nil} when guild is not configured" do
      interaction = %{
        guild_id: "unconfigured_guild",
        channel_id: "any_channel"
      }

      assert {:ok, nil} = ChannelValidator.validate_channel(interaction, :user)
    end
  end

  describe "validate_channel/2 edge cases" do
    test "returns {:ok, nil} when channel_id is nil" do
      guild_config_fixture(%{
        guild_id: "test_guild",
        admin_channel_id: "admin_channel_123"
      })

      interaction = %{
        guild_id: "test_guild",
        channel_id: nil
      }

      assert {:ok, nil} = ChannelValidator.validate_channel(interaction, :admin)
    end

    test "returns {:ok, nil} when guild_id is nil" do
      interaction = %{
        guild_id: nil,
        channel_id: "some_channel"
      }

      assert {:ok, nil} = ChannelValidator.validate_channel(interaction, :admin)
    end

    test "handles integer channel IDs from Discord" do
      guild_config_fixture(%{
        guild_id: "123456789",
        admin_channel_id: "999888777"
      })

      interaction = %{
        guild_id: "123456789",
        channel_id: 999_888_777  # Integer from Discord API
      }

      assert {:ok, nil} = ChannelValidator.validate_channel(interaction, :admin)
    end

    test "handles string channel IDs compared to integer from Discord" do
      guild_config_fixture(%{
        guild_id: "123456789",
        admin_channel_id: "999888777"
      })

      interaction = %{
        guild_id: "123456789",
        channel_id: "111222333"  # Wrong channel as string
      }

      assert {:ok, warning} = ChannelValidator.validate_channel(interaction, :admin)
      assert warning != nil
    end
  end

  describe "format_warning/2" do
    test "formats admin channel warning correctly" do
      warning = ChannelValidator.format_warning(:admin, "admin_channel_123")

      assert warning =~ "⚠️"
      assert warning =~ "admin"
      assert warning =~ "<#admin_channel_123>"
    end

    test "formats user channel warning correctly" do
      warning = ChannelValidator.format_warning(:user, "user_channel_456")

      assert warning =~ "⚠️"
      assert warning =~ "user"
      assert warning =~ "<#user_channel_456>"
    end
  end
end
