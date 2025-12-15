defmodule RaffleBot.Discord.Commands.SetupRaffleAdmin do
  @moduledoc """
  Handles the /setup_raffle_admin command

  Initial setup command for configuring the bot on a Discord server.
  Should be run from the admin channel by a user with "Manage Server" permissions.

  Stores:
  - Admin channel (inferred from where command is invoked)
  - User channel (parameter)
  - Bot Boss role (parameter)
  - Control Panel (created automatically in admin channel)
  """

  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.GuildConfig
  alias RaffleBot.Discord.Components.ControlPanel

  require Logger

  def handle(interaction) do
    # Extract parameters from interaction
    with {:ok, guild_id} <- extract_guild_id(interaction),
         {:ok, admin_channel_id} <- extract_channel_id(interaction),
         {:ok, options} <- extract_options(interaction),
         {:ok, bot_boss_role_id} <- extract_role(options, "bot_boss_role"),
         {:ok, user_channel_id} <- extract_channel(options, "user_channel") do
      # Create or update guild configuration
      attrs = %{
        guild_id: guild_id,
        admin_channel_id: admin_channel_id,
        user_channel_id: user_channel_id,
        bot_boss_role_id: bot_boss_role_id
      }

      case GuildConfig.upsert_guild_config(attrs) do
        {:ok, config} ->
          # Create control panel in admin channel
          case create_control_panel(admin_channel_id, config) do
            {:ok, thread_id} ->
              success_response(admin_channel_id, user_channel_id, bot_boss_role_id, thread_id)
              |> send_response(interaction)

            {:error, reason} ->
              # Config saved but control panel creation failed
              Logger.warning("Failed to create control panel: #{inspect(reason)}")

              success_response_no_panel(admin_channel_id, user_channel_id, bot_boss_role_id)
              |> send_response(interaction)
          end

        {:error, changeset} ->
          error_response(changeset)
          |> send_response(interaction)
      end
    else
      {:error, reason} ->
        error_response(reason)
        |> send_response(interaction)
    end
  end

  # Creates the control panel forum thread in the admin channel
  defp create_control_panel(admin_channel_id, config) do
    # Build control panel message
    message = ControlPanel.build_message([])

    # Create forum thread
    case discord_api().start_forum_thread(
           admin_channel_id,
           "🎰 Raffle Control Panel",
           message
         ) do
      {:ok, %{"id" => thread_id, "message" => %{"id" => message_id}}} ->
        # Update config with control panel IDs
        GuildConfig.update_guild_config(config, %{
          control_panel_thread_id: thread_id,
          control_panel_message_id: message_id
        })

        {:ok, thread_id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helpers

  defp extract_guild_id(%{guild_id: nil}), do: {:error, :missing_guild}
  defp extract_guild_id(%{guild_id: guild_id}), do: {:ok, to_string(guild_id)}
  defp extract_guild_id(_), do: {:error, :missing_guild}

  defp extract_channel_id(%{channel_id: nil}), do: {:error, :missing_channel}
  defp extract_channel_id(%{channel_id: channel_id}), do: {:ok, to_string(channel_id)}
  defp extract_channel_id(_), do: {:error, :missing_channel}

  defp extract_options(%{data: %{options: options}}), do: {:ok, options}
  defp extract_options(_), do: {:error, :missing_options}

  defp extract_role(options, key) do
    case Enum.find(options, fn opt -> opt.name == key end) do
      %{value: value} -> {:ok, to_string(value)}
      nil -> {:error, :missing_role}
    end
  end

  defp extract_channel(options, key) do
    case Enum.find(options, fn opt -> opt.name == key end) do
      %{value: value} -> {:ok, to_string(value)}
      nil -> {:error, :missing_channel_param}
    end
  end

  defp success_response(admin_channel_id, user_channel_id, bot_boss_role_id, control_panel_thread_id) do
    %{
      type: 4,
      data: %{
        content: """
        ✅ **Raffle Bot Configured Successfully!**

        **Admin Channel:** <##{admin_channel_id}> (this channel)
        **User Channel:** <##{user_channel_id}>
        **Bot Boss Role:** <@&#{bot_boss_role_id}>

        🎰 **Control Panel:** <##{control_panel_thread_id}>
        Use the Control Panel to create and manage raffles!

        You can update this configuration anytime with `/configure_raffle_admin`.
        """,
        flags: 64
      }
    }
  end

  defp success_response_no_panel(admin_channel_id, user_channel_id, bot_boss_role_id) do
    %{
      type: 4,
      data: %{
        content: """
        ✅ **Raffle Bot Configured Successfully!**

        **Admin Channel:** <##{admin_channel_id}> (this channel)
        **User Channel:** <##{user_channel_id}>
        **Bot Boss Role:** <@&#{bot_boss_role_id}>

        ⚠️ Control Panel could not be created automatically.
        You can still use `/setup_raffle` to create raffles.

        You can update this configuration anytime with `/configure_raffle_admin`.
        """,
        flags: 64
      }
    }
  end

  defp error_response(%Ecto.Changeset{} = changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    error_text = inspect(errors, pretty: true)

    %{
      type: 4,
      data: %{
        content: """
        ❌ **Configuration Error**

        Failed to save configuration:
        ```
        #{error_text}
        ```

        Please check your inputs and try again.
        """,
        flags: 64
      }
    }
  end

  defp error_response(:missing_guild) do
    %{
      type: 4,
      data: %{
        content: "❌ This command must be used in a Discord server.",
        flags: 64
      }
    }
  end

  defp error_response(:missing_channel) do
    %{
      type: 4,
      data: %{
        content: "❌ Could not determine the current channel.",
        flags: 64
      }
    }
  end

  defp error_response(:missing_role) do
    %{
      type: 4,
      data: %{
        content: "❌ Please specify the Bot Boss role parameter.",
        flags: 64
      }
    }
  end

  defp error_response(:missing_channel_param) do
    %{
      type: 4,
      data: %{
        content: "❌ Please specify the user channel parameter.",
        flags: 64
      }
    }
  end

  defp error_response(_reason) do
    %{
      type: 4,
      data: %{
        content: "❌ An unexpected error occurred. Please try again.",
        flags: 64
      }
    }
  end

  defp send_response(response, interaction) do
    discord_api().create_interaction_response(interaction, response.type, response.data)
  end
end
