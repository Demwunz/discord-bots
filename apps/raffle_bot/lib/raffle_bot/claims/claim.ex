defmodule RaffleBot.Claims.Claim do
  @moduledoc """
  The Claim Ecto schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias RaffleBot.Raffles.Raffle

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "claims" do
    field :user_id, :integer
    field :spot_number, :integer
    field :is_paid, :boolean, default: false

    belongs_to :raffle, Raffle

    timestamps()
  end

  @doc false
  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:user_id, :spot_number, :is_paid, :raffle_id])
    |> validate_required([:user_id, :spot_number, :is_paid, :raffle_id])
  end
end
