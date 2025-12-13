defmodule RaffleBot.Repo.Migrations.CreateGuildConfigurations do
  use Ecto.Migration

  def change do
    create table(:guild_configurations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :guild_id, :text, null: false
      add :admin_channel_id, :text, null: false
      add :user_channel_id, :text, null: false
      add :bot_boss_role_id, :text, null: false

      timestamps()
    end

    create unique_index(:guild_configurations, [:guild_id])
  end
end
