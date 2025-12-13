defmodule RaffleBot.GuildConfig do
  @moduledoc """
  The GuildConfig context.

  Manages guild (Discord server) configurations including:
  - Admin and user channel assignments
  - Bot Boss role configuration
  - Per-guild settings
  """

  import Ecto.Query, warn: false
  alias RaffleBot.Repo

  alias RaffleBot.GuildConfig.GuildConfiguration

  @doc """
  Returns the list of guild configurations.

  ## Examples

      iex> list_guild_configs()
      [%GuildConfiguration{}, ...]

  """
  def list_guild_configs do
    Repo.all(GuildConfiguration)
  end

  @doc """
  Gets a single guild configuration by ID.

  Raises `Ecto.NoResultsError` if the GuildConfiguration does not exist.

  ## Examples

      iex> get_guild_config!(123)
      %GuildConfiguration{}

      iex> get_guild_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_guild_config!(id), do: Repo.get!(GuildConfiguration, id)

  @doc """
  Gets a guild configuration by guild_id.

  Returns nil if not found.

  ## Examples

      iex> get_guild_config_by_guild_id("123456789")
      %GuildConfiguration{}

      iex> get_guild_config_by_guild_id("nonexistent")
      nil

  """
  def get_guild_config_by_guild_id(guild_id) do
    Repo.get_by(GuildConfiguration, guild_id: guild_id)
  end

  @doc """
  Creates a guild configuration.

  ## Examples

      iex> create_guild_config(%{field: value})
      {:ok, %GuildConfiguration{}}

      iex> create_guild_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_guild_config(attrs \\ %{}) do
    %GuildConfiguration{}
    |> GuildConfiguration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a guild configuration.

  ## Examples

      iex> update_guild_config(guild_config, %{field: new_value})
      {:ok, %GuildConfiguration{}}

      iex> update_guild_config(guild_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_guild_config(%GuildConfiguration{} = guild_config, attrs) do
    guild_config
    |> GuildConfiguration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a guild configuration.

  ## Examples

      iex> delete_guild_config(guild_config)
      {:ok, %GuildConfiguration{}}

      iex> delete_guild_config(guild_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_guild_config(%GuildConfiguration{} = guild_config) do
    Repo.delete(guild_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking guild configuration changes.

  ## Examples

      iex> change_guild_config(guild_config)
      %Ecto.Changeset{data: %GuildConfiguration{}}

  """
  def change_guild_config(%GuildConfiguration{} = guild_config, attrs \\ %{}) do
    GuildConfiguration.changeset(guild_config, attrs)
  end

  @doc """
  Creates or updates a guild configuration based on guild_id.

  If a configuration for the guild_id exists, it updates it.
  Otherwise, it creates a new configuration.

  ## Examples

      iex> upsert_guild_config(%{guild_id: "123", ...})
      {:ok, %GuildConfiguration{}}

  """
  def upsert_guild_config(attrs) do
    case get_guild_config_by_guild_id(attrs.guild_id) do
      nil ->
        create_guild_config(attrs)

      existing ->
        update_guild_config(existing, attrs)
    end
  end

  @doc """
  Checks if a guild has a configuration.

  ## Examples

      iex> has_guild_config?("123456789")
      true

      iex> has_guild_config?("nonexistent")
      false

  """
  def has_guild_config?(guild_id) do
    case get_guild_config_by_guild_id(guild_id) do
      nil -> false
      _ -> true
    end
  end
end
