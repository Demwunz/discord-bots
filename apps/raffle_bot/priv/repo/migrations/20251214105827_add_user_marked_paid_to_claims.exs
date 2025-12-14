defmodule RaffleBot.Repo.Migrations.AddUserMarkedPaidToClaims do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      add :user_marked_paid, :boolean, default: false
      add :user_marked_paid_at, :utc_datetime
    end
  end
end
