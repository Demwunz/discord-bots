defmodule RaffleBot.RafflesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaffleBot.Raffles` context.
  """

  @doc """
  Generate a raffle.
  """
  def raffle_fixture(attrs \\ %{}) do
    {:ok, raffle} =
      attrs
      |> Enum.into(%{
        title: "some title",
        price: "120.5",
        total_spots: 42,
        message_id: 12345,
        channel_id: 67890,
        description: "some description",
        duration_days: 7,
        photo_url: "http://example.com/photo.png",
        grading_link: "http://example.com/grading",
        international_shipping: "Yes"
      })
      |> RaffleBot.Raffles.create_raffle()

    raffle
  end
end
