defmodule RaffleBot.Repo.Migrations.AddRaffleEnhancements do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :photo_url, :text
      add :grading_link, :text
      add :duration_days, :integer
      add :international_shipping, :text
      add :auto_close_at, :utc_datetime
      add :closed_at, :utc_datetime
    end

    create_if_not_exists index(:claims, [:user_id])
    create_if_not_exists index(:raffles, [:active])
    create_if_not_exists index(:raffles, [:auto_close_at])
  end
end
