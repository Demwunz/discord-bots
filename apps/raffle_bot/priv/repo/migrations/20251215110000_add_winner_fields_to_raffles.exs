defmodule RaffleBot.Repo.Migrations.AddWinnerFieldsToRaffles do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :winner_user_id, :string
      add :winner_announced_at, :utc_datetime
      add :winner_spot_number, :integer
      add :shipping_details, :map
      add :shipping_submitted_at, :utc_datetime
    end

    # Index for querying raffles by winner
    create index(:raffles, [:winner_user_id])
  end
end
