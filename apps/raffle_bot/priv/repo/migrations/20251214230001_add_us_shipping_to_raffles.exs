defmodule RaffleBot.Repo.Migrations.AddUsShippingToRaffles do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :us_shipping, :text, default: "Free USPS Ground Advantage"
    end
  end
end
