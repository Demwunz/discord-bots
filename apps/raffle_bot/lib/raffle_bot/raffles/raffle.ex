defmodule RaffleBot.Raffles.Raffle do
  @moduledoc """
  The Raffle Ecto schema with all PRD-required fields.
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
    field :photo_url, :string
    field :grading_link, :string
    field :duration_days, :integer, default: 7
    field :international_shipping, :string, default: "Contact Admin"
    field :active, :boolean, default: true
    field :closed_at, :utc_datetime
    field :auto_close_at, :utc_datetime

    has_many :claims, Claim

    timestamps()
  end

  @doc false
  def changeset(raffle, attrs) do
    raffle
    |> cast(attrs, [
      :message_id,
      :channel_id,
      :title,
      :price,
      :total_spots,
      :description,
      :photo_url,
      :grading_link,
      :duration_days,
      :international_shipping,
      :active,
      :closed_at,
      :auto_close_at
    ])
    |> validate_required([
      :channel_id,
      :title,
      :price,
      :total_spots,
      :description
    ])
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_number(:total_spots, greater_than: 0)
    |> validate_number(:duration_days, greater_than: 0, less_than_or_equal_to: 30)
    |> set_auto_close_date()
  end

  defp set_auto_close_date(changeset) do
    days = get_field(changeset, :duration_days)
    auto_close_at = 
      DateTime.utc_now()
      |> DateTime.add(days * 86400, :second) # 86400 seconds in a day
      |> DateTime.truncate(:second)
    
    put_change(changeset, :auto_close_at, auto_close_at)
  end
end
