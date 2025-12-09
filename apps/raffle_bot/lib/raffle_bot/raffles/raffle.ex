defmodule RaffleBot.Raffles.Raffle do
  @moduledoc """
  The Raffle Ecto schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias RaffleBot.Claims.Claim

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "raffles" do
    field :message_id, :integer
    field :channel_id, :integer
    field :title, :string
    field :price, :decimal
    field :total_spots, :integer
    field :description, :string
    field :active, :boolean, default: true
    field :is_complete, :boolean, default: false

    has_many :claims, Claim

    timestamps()
  end

  @doc false
  def changeset(raffle, attrs) do
    raffle
    # Stream data into a changeset (a struct that contains constraints and validations)
    |> cast(attrs, [
      :message_id,
      :channel_id,
      :title,
      :price,
      :total_spots,
      :description,
      :active,
      :is_complete
    ])
    # Validate the presence of the required fields
    |> validate_required([
      :message_id,
      :channel_id,
      :title,
      :price,
      :total_spots,
      :description,
      :active,
      :is_complete
    ])
  end
end
