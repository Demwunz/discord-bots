defmodule RaffleBot.Discord.ChannelValidator do
  @moduledoc """
  Channel validation utilities for Discord interactions.

  Provides soft warnings when commands are used in non-recommended channels.
  Follows hybrid enforcement approach: warns but allows execution.
  """

  alias RaffleBot.GuildConfig

  @doc """
  Validates if a command is being used in the recommended channel.

  Uses soft enforcement: Returns a warning message if wrong channel,
  but allows command to execute anyway.

  ## Parameters
  - interaction: The Discord interaction struct with guild_id and channel_id
  - command_type: Either :admin or :user

  ## Returns
  - `{:ok, nil}` if in correct channel or guild not configured
  - `{:ok, warning_message}` if in wrong channel (soft warning)

  ## Examples
      iex> validate_channel(interaction, :admin)
      {:ok, nil}

      iex> validate_channel(interaction, :admin)
      {:ok, "⚠️ Tip: Admin commands work best in <#123456>"}
  """
  def validate_channel(interaction, command_type) do
    with {:ok, guild_id} <- extract_guild_id(interaction),
         {:ok, channel_id} <- extract_channel_id(interaction),
         {:ok, config} <- get_guild_config(guild_id) do
      check_channel(channel_id, config, command_type)
    else
      {:error, _reason} -> {:ok, nil}  # No validation if missing data
    end
  end

  @doc """
  Formats a warning message for wrong channel usage.

  ## Parameters
  - command_type: :admin or :user
  - correct_channel_id: The channel ID where command should be used

  ## Returns
  String with formatted warning message
  """
  def format_warning(:admin, channel_id) do
    """
    ⚠️ **Tip:** Admin commands work best in <##{channel_id}>

    This command will still work here, but using the designated admin channel helps keep things organized.
    """
  end

  def format_warning(:user, channel_id) do
    """
    ⚠️ **Tip:** User commands are intended for <##{channel_id}>

    This command will still work here, but the designated user channel is recommended.
    """
  end

  # Private helpers

  defp extract_guild_id(%{guild_id: nil}), do: {:error, :missing_guild}
  defp extract_guild_id(%{guild_id: guild_id}), do: {:ok, guild_id}
  defp extract_guild_id(_), do: {:error, :missing_guild}

  defp extract_channel_id(%{channel_id: nil}), do: {:error, :missing_channel}
  defp extract_channel_id(%{channel_id: channel_id}), do: {:ok, channel_id}
  defp extract_channel_id(_), do: {:error, :missing_channel}

  defp get_guild_config(guild_id) do
    case GuildConfig.get_guild_config_by_guild_id(guild_id) do
      nil -> {:error, :not_configured}
      config -> {:ok, config}
    end
  end

  defp check_channel(channel_id, config, :admin) do
    correct_channel = config.admin_channel_id

    if same_channel?(channel_id, correct_channel) do
      {:ok, nil}
    else
      {:ok, format_warning(:admin, correct_channel)}
    end
  end

  defp check_channel(channel_id, config, :user) do
    correct_channel = config.user_channel_id

    if same_channel?(channel_id, correct_channel) do
      {:ok, nil}
    else
      {:ok, format_warning(:user, correct_channel)}
    end
  end

  # Compare channel IDs, normalizing for integer/string differences
  defp same_channel?(channel_id, config_channel_id) do
    normalize_id(channel_id) == normalize_id(config_channel_id)
  end

  # Normalize channel IDs to strings for comparison
  defp normalize_id(id) when is_integer(id), do: Integer.to_string(id)
  defp normalize_id(id) when is_binary(id), do: id
  defp normalize_id(_), do: nil
end
