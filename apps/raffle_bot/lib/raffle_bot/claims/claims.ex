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

  def get_claims_from_last_24_hours do
    from(c in Claim, where: c.inserted_at > ago(24, "hour"))
    |> Repo.all()
  end

    @doc """
    Gets all claims for a specific user.
    """
    def get_claims_by_user(user_id) do
      from(c in Claim, 
        where: c.user_id == ^user_id,
        order_by: [desc: c.inserted_at]
      )
      |> Repo.all()
    end

    @doc """
    Gets claims since a datetime.
    """
    def get_claims_since(datetime) do
      from(c in Claim,
        where: c.inserted_at > ^datetime,
        order_by: [desc: c.inserted_at]
      )
      |> Repo.all()
    end
end
