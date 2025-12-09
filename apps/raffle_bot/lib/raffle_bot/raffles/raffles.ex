defmodule RaffleBot.Raffles do
  @moduledoc """
  The Raffles context.
  """

  import Ecto.Query, warn: false
  alias RaffleBot.Repo

  alias RaffleBot.Raffles.Raffle

  defdelegate change_raffle(raffle, attrs), to: Raffle

  def create_raffle(attrs \\ %{}) do
    %Raffle{}
    |> Raffle.changeset(attrs)
    |> Repo.insert()
  end

  def get_raffle!(id), do: Repo.get!(Raffle, id)

  def list_raffles(), do: Repo.all(Raffle)

end
