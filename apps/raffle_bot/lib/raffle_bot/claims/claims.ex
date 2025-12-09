defmodule RaffleBot.Claims do
  @moduledoc """
  The Claims context.
  """

  import Ecto.Query, warn: false
  alias RaffleBot.Repo

  alias RaffleBot.Claims.Claim

  def create_claim(attrs \\ %{}) do
    %Claim{}
    |> Claim.changeset(attrs)
    |> Repo.insert()
  end

  def get_claims_by_raffle(raffle_id) do
    from(c in Claim, where: c.raffle_id == ^raffle_id)
    |> Repo.all()
  end

  def get_claim!(id), do: Repo.get!(Claim, id)

  def update_claim(%Claim{} = claim, attrs) do
    claim
    |> Claim.changeset(attrs)
    |> Repo.update()
  end

end
