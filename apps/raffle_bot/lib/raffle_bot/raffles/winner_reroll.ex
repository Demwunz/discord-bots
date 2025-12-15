defmodule RaffleBot.Raffles.WinnerReroll do
  @moduledoc """
  Schema for tracking winner re-rolls for audit and transparency.

  Each time an admin re-rolls a winner, a record is created documenting
  who was the previous winner, who re-rolled them, and why.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias RaffleBot.Raffles.Raffle

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "winner_rerolls" do
    field :previous_winner_id, :string
    field :previous_winner_spots, {:array, :integer}, default: []
    field :rerolled_by_id, :string
    field :reason, :string
    field :rerolled_at, :utc_datetime

    belongs_to :raffle, Raffle

    timestamps()
  end

  @doc false
  def changeset(reroll, attrs) do
    reroll
    |> cast(attrs, [
      :raffle_id,
      :previous_winner_id,
      :previous_winner_spots,
      :rerolled_by_id,
      :reason,
      :rerolled_at
    ])
    |> validate_required([
      :raffle_id,
      :previous_winner_id,
      :rerolled_by_id,
      :reason,
      :rerolled_at
    ])
    |> foreign_key_constraint(:raffle_id)
  end
end
