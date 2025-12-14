defmodule RaffleBot.Repo.Migrations.AddPhotoUrlsToRaffles do
  use Ecto.Migration

  def change do
    alter table(:raffles) do
      add :photo_urls, {:array, :string}, default: []
    end
  end
end
