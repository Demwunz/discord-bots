defmodule RaffleBot.Discord.Commands.ConfigureRaffleAdmin do
  @moduledoc """
  Handles the /configure_raffle_admin command

  Allows updating the bot configuration on a Discord server.
  Should be run by a user with the Bot Boss role.

  Updates:
  - Admin channel (inferred from where command is invoked)
  - User channel (parameter)
  - Bot Boss role (parameter)
  """

  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.GuildConfig
  alias RaffleBot.Discord.Authorization

  def handle(interaction) do
    # First check authorization
    case Authorization.authorize_admin(interaction) do
      {:ok, _config} ->
        handle_authorized(interaction)

      {:error, reason} ->
        Authorization.unauthorized_response(reason)
        |> send_response(interaction)
    end
  end

  defp handle_authorized(interaction) do
    # Extract parameters from interaction
    with {:ok, guild_id} <- extract_guild_id(interaction),
         {:ok, admin_channel_id} <- extract_channel_id(interaction),
         {:ok, options} <- extract_options(interaction),
         {:ok, bot_boss_role_id} <- extract_role(options, "bot_boss_role"),
         {:ok, user_channel_id} <- extract_channel(options, "user_channel") do
      # Update guild configuration
      attrs = %{
        guild_id: guild_id,
        admin_channel_id: admin_channel_id,
        user_channel_id: user_channel_id,
        bot_boss_role_id: bot_boss_role_id
      }

      case GuildConfig.upsert_guild_config(attrs) do
        {:ok, _config} ->
          success_response(admin_channel_id, user_channel_id, bot_boss_role_id)
          |> send_response(interaction)

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

  defp success_response(admin_channel_id, user_channel_id, bot_boss_role_id) do
    %{
      type: 4,
      data: %{
        content: """
        ✅ **Configuration Updated Successfully!**

        **Admin Channel:** <##{admin_channel_id}> (this channel)
        **User Channel:** <##{user_channel_id}>
        **Bot Boss Role:** <@&#{bot_boss_role_id}>

        The bot configuration has been updated. All changes are now active.
        """,
        flags: 64  # Ephemeral
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

        Failed to update configuration:
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
