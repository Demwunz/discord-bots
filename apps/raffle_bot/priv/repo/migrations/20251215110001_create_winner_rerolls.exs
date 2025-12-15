defmodule RaffleBot.Repo.Migrations.CreateWinnerRerolls do
  use Ecto.Migration

  def change do
    create table(:winner_rerolls, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :raffle_id, references(:raffles, type: :binary_id, on_delete: :delete_all), null: false
      add :previous_winner_id, :string, null: false
      add :previous_winner_spots, {:array, :integer}, default: []
      add :rerolled_by_id, :string, null: false
      add :reason, :string, null: false
      add :rerolled_at, :utc_datetime, null: false

      timestamps()
    end

    create index(:winner_rerolls, [:raffle_id])
  end
end
