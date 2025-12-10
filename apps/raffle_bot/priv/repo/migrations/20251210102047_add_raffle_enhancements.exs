defmodule RaffleBot.Repo.Migrations.AddRaffleEnhancements do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add_if_not_exists :photo_url, :text
      add_if_not_exists :grading_link, :text
      add_if_not_exists :duration_days, :integer
      add_if_not_exists :international_shipping, :text
      add_if_not_exists :auto_close_at, :utc_datetime
      add_if_not_exists :closed_at, :utc_datetime
    end

    create_if_not_exists index(:claims, [:user_id])
    create_if_not_exists index(:raffles, [:active])
    create_if_not_exists index(:raffles, [:auto_close_at])
  end
end
