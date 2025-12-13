defmodule RaffleBot.GuildConfig.GuildConfiguration do
  @moduledoc """
  The GuildConfiguration Ecto schema for storing per-guild settings.

  Each Discord guild (server) can have its own configuration for:
  - Admin channel (where admin commands should be used)
  - User channel (where user-facing raffle posts appear)
  - Bot Boss role (which role has admin permissions)
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "guild_configurations" do
    field :guild_id, :string
    field :admin_channel_id, :string
    field :user_channel_id, :string
    field :bot_boss_role_id, :string

    timestamps()
  end

  @doc false
  def changeset(guild_config, attrs) do
    guild_config
    |> cast(attrs, [:guild_id, :admin_channel_id, :user_channel_id, :bot_boss_role_id])
    |> validate_required([:guild_id, :admin_channel_id, :user_channel_id, :bot_boss_role_id])
    |> unique_constraint(:guild_id)
  end
end
