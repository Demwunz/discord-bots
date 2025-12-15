defmodule RaffleBot.Repo.Migrations.AddControlPanelToGuildConfigurations do
  use Ecto.Migration

  def change do
    alter table(:guild_configurations) do
      add :control_panel_thread_id, :string
      add :control_panel_message_id, :string
    end
  end
end
