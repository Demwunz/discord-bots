defmodule RaffleBot.Discord.AuthorizationTest do
  use RaffleBot.DataCase

  alias RaffleBot.Discord.Authorization
  import RaffleBot.GuildConfigFixtures

  describe "authorize_admin/1" do
    test "returns {:ok, config} when user has Bot Boss role" do
      config = guild_config_fixture(%{
        guild_id: "test_guild_123",
        bot_boss_role_id: "bot_boss_role_456"
      })

      interaction = %{
        guild_id: "test_guild_123",
        member: %{
          roles: ["bot_boss_role_456", "other_role_789"]
        }
      }

      assert {:ok, returned_config} = Authorization.authorize_admin(interaction)
      assert returned_config.id == config.id
    end

    test "returns {:ok, config} when roles are integers and config is string" do
      guild_config_fixture(%{
        guild_id: "test_guild_123",
        bot_boss_role_id: "123456789"
      })

      interaction = %{
        guild_id: "test_guild_123",
        member: %{
          roles: [123_456_789, 987_654_321]
        }
      }

      assert {:ok, _config} = Authorization.authorize_admin(interaction)
    end

    test "returns {:ok, config} when roles are strings and config is integer-like string" do
      guild_config_fixture(%{
        guild_id: "test_guild_123",
        bot_boss_role_id: "999888777"
      })

      interaction = %{
        guild_id: "test_guild_123",
        member: %{
          roles: ["999888777", "111222333"]
        }
      }

      assert {:ok, _config} = Authorization.authorize_admin(interaction)
    end

    test "returns {:error, :not_configured} when guild has no configuration" do
      interaction = %{
        guild_id: "unconfigured_guild",
        member: %{
          roles: ["some_role"]
        }
      }

      assert {:error, :not_configured} = Authorization.authorize_admin(interaction)
    end

    test "returns {:error, :missing_role} when user doesn't have Bot Boss role" do
      guild_config_fixture(%{
        guild_id: "test_guild_123",
        bot_boss_role_id: "required_role_456"
      })

      interaction = %{
        guild_id: "test_guild_123",
        member: %{
          roles: ["other_role_789", "another_role_012"]
        }
      }

      assert {:error, :missing_role} = Authorization.authorize_admin(interaction)
    end

    test "returns {:error, :missing_role} when user has no roles" do
      guild_config_fixture(%{
        guild_id: "test_guild_123",
        bot_boss_role_id: "required_role_456"
      })

      interaction = %{
        guild_id: "test_guild_123",
        member: %{
          roles: []
        }
      }

      assert {:error, :missing_role} = Authorization.authorize_admin(interaction)
    end

    test "returns {:error, :missing_member} when member is nil" do
      guild_config_fixture(%{
        guild_id: "test_guild_123",
        bot_boss_role_id: "required_role_456"
      })

      interaction = %{
        guild_id: "test_guild_123",
        member: nil
      }

      assert {:error, :missing_member} = Authorization.authorize_admin(interaction)
    end

    test "returns {:error, :missing_member} when roles is nil" do
      guild_config_fixture(%{
        guild_id: "test_guild_123",
        bot_boss_role_id: "required_role_456"
      })

      interaction = %{
        guild_id: "test_guild_123",
        member: %{
          roles: nil
        }
      }

      assert {:error, :missing_member} = Authorization.authorize_admin(interaction)
    end

    test "returns {:error, :missing_guild} when guild_id is nil" do
      interaction = %{
        guild_id: nil,
        member: %{
          roles: ["some_role"]
        }
      }

      assert {:error, :missing_guild} = Authorization.authorize_admin(interaction)
    end
  end

  describe "unauthorized_response/1" do
    test "returns ephemeral error for :not_configured" do
      response = Authorization.unauthorized_response(:not_configured)

      assert %{
               type: 4,
               data: %{
                 content: content,
                 flags: 64
               }
             } = response

      assert content =~ "not configured"
      assert content =~ "setup_raffle_admin"
    end

    test "returns ephemeral error for :missing_role" do
      response = Authorization.unauthorized_response(:missing_role)

      assert %{
               type: 4,
               data: %{
                 content: content,
                 flags: 64
               }
             } = response

      assert content =~ "Bot Boss"
      assert content =~ "role"
    end

    test "returns ephemeral error for :missing_member" do
      response = Authorization.unauthorized_response(:missing_member)

      assert %{
               type: 4,
               data: %{
                 content: content,
                 flags: 64
               }
             } = response

      assert content =~ "verify"
      assert content =~ "permissions"
    end

    test "returns ephemeral error for :missing_guild" do
      response = Authorization.unauthorized_response(:missing_guild)

      assert %{
               type: 4,
               data: %{
                 content: content,
                 flags: 64
               }
             } = response

      assert content =~ "server"
    end

    test "returns generic error for unknown reason" do
      response = Authorization.unauthorized_response(:unknown_error)

      assert %{
               type: 4,
               data: %{
                 content: content,
                 flags: 64
               }
             } = response

      assert content =~ "Unauthorized"
    end
  end
end
