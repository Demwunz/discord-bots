defmodule RaffleBot.Discord.Authorization do
  @moduledoc """
  Authorization utilities for Discord interactions.

  Handles guild-specific role-based authorization for admin commands.
  Uses guild configuration from database to determine required roles.
  """

  alias RaffleBot.GuildConfig

  @doc """
  Authorizes an admin command based on guild configuration and user roles.

  Checks if:
  1. Guild has a configuration (has run /setup_raffle_admin)
  2. User has the Bot Boss role defined in guild configuration
  3. User member data is present

  ## Parameters
  - interaction: The Discord interaction struct containing guild_id and member data

  ## Returns
  - `{:ok, guild_config}` if user is authorized
  - `{:error, :not_configured}` if guild has no configuration
  - `{:error, :missing_role}` if user doesn't have Bot Boss role
  - `{:error, :missing_member}` if member data is unavailable
  - `{:error, :missing_guild}` if guild_id is nil

  ## Examples
      iex> authorize_admin(interaction)
      {:ok, %GuildConfiguration{}}

      iex> authorize_admin(interaction)
      {:error, :missing_role}
  """
  def authorize_admin(interaction) do
    with {:ok, guild_id} <- extract_guild_id(interaction),
         {:ok, config} <- get_guild_config(guild_id),
         {:ok, member} <- extract_member(interaction),
         :ok <- verify_role(member, config.bot_boss_role_id) do
      {:ok, config}
    end
  end

  @doc """
  Creates an unauthorized error response for Discord interactions.

  Returns a properly formatted ephemeral interaction response with
  a user-friendly error message based on the error reason.

  ## Parameters
  - reason: Atom indicating why authorization failed
    - :not_configured - Guild hasn't run setup
    - :missing_role - User lacks Bot Boss role
    - :missing_member - Member data unavailable
    - :missing_guild - Guild ID missing
    - Other - Generic unauthorized message

  ## Returns
  Map with Discord interaction response format (type 4, ephemeral)
  """
  def unauthorized_response(reason) do
    message = error_message(reason)

    %{
      type: 4,
      data: %{
        content: message,
        flags: 64  # Ephemeral flag
      }
    }
  end

  # Private helpers

  defp extract_guild_id(%{guild_id: nil}), do: {:error, :missing_guild}
  defp extract_guild_id(%{guild_id: guild_id}), do: {:ok, guild_id}
  defp extract_guild_id(_), do: {:error, :missing_guild}

  defp get_guild_config(guild_id) do
    case GuildConfig.get_guild_config_by_guild_id(guild_id) do
      nil -> {:error, :not_configured}
      config -> {:ok, config}
    end
  end

  defp extract_member(%{member: nil}), do: {:error, :missing_member}
  defp extract_member(%{member: %{roles: nil}}), do: {:error, :missing_member}
  defp extract_member(%{member: member}), do: {:ok, member}
  defp extract_member(_), do: {:error, :missing_member}

  defp verify_role(member, required_role_id) do
    roles = member.roles || []

    if has_role?(roles, required_role_id) do
      :ok
    else
      {:error, :missing_role}
    end
  end

  defp has_role?(roles, role_id) when is_list(roles) do
    normalized_required = normalize_id(role_id)
    Enum.any?(roles, fn role -> normalize_id(role) == normalized_required end)
  end

  defp has_role?(_, _), do: false

  # Normalize role IDs to strings for comparison
  # Discord can send roles as integers or strings
  defp normalize_id(id) when is_integer(id), do: Integer.to_string(id)
  defp normalize_id(id) when is_binary(id), do: id
  defp normalize_id(_), do: nil

  defp error_message(:not_configured) do
    """
    ⚠️ **Server Not Configured**

    This server hasn't been configured yet. An admin with "Manage Server" permissions needs to run `/setup_raffle_admin` first.
    """
  end

  defp error_message(:missing_role) do
    """
    ❌ **Unauthorized**

    This command requires the **Bot Boss** role. Please contact a server admin if you believe this is an error.
    """
  end

  defp error_message(:missing_member) do
    """
    ⚠️ **Unable to Verify Permissions**

    Could not verify your server permissions. Please try again or contact support.
    """
  end

  defp error_message(:missing_guild) do
    """
    ⚠️ **Invalid Context**

    This command must be used within a Discord server.
    """
  end

  defp error_message(_) do
    """
    ❌ **Unauthorized**

    You don't have permission to use this command.
    """
  end
end
