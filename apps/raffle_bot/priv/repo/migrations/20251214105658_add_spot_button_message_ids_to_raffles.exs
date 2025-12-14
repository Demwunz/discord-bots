defmodule RaffleBot.Repo.Migrations.AddSpotButtonMessageIdsToRaffles do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :spot_button_message_ids, {:array, :text}, default: []
    end
  end
end
