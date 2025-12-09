defmodule RaffleBot.Repo.Migrations.CreateRafflesAndClaims do
  use Ecto.Migration

  def change do
    create table(:raffles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :message_id, :bigint
      add :channel_id, :bigint
      add :title, :text
      add :price, :decimal
      add :total_spots, :integer
      add :description, :text
      add :active, :boolean, default: true
      add :is_complete, :boolean, default: false

      timestamps()
    end

    create table(:claims, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :bigint
      add :spot_number, :integer
      add :is_paid, :boolean, default: false
      add :raffle_id, references(:raffles, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:claims, [:raffle_id, :spot_number], unique: true)
  end
end
