defmodule RaffleBot.Repo.Migrations.AddPaymentAndAdminThreadToRaffles do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :payment_details, :text
      add :admin_thread_id, :text
      add :admin_thread_message_id, :text
    end
  end
end
