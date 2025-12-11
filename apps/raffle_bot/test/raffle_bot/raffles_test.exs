defmodule RaffleBot.RafflesTest do
  use RaffleBot.DataCase

  alias RaffleBot.Raffles

  describe "raffles" do
    alias RaffleBot.Raffles.Raffle

    import RaffleBot.RafflesFixtures

    @invalid_attrs %{title: nil, price: nil, total_spots: nil}

    test "list_raffles/0 returns all raffles" do
      raffle = raffle_fixture()
      assert Raffles.list_raffles() == [raffle]
    end

    test "get_raffle!/1 returns the raffle with given id" do
      raffle = raffle_fixture()
      assert Raffles.get_raffle!(raffle.id) == raffle
    end

    test "create_raffle/1 with valid data creates a raffle" do
      valid_attrs = %{
        title: "some title",
        price: "120.5",
        total_spots: 42,
        message_id: 12345,
        channel_id: 67890,
        description: "some description"
      }

      assert {:ok, %Raffle{} = raffle} = Raffles.create_raffle(valid_attrs)
      assert raffle.title == "some title"
      assert raffle.price == Decimal.new("120.5")
      assert raffle.total_spots == 42
    end

    test "create_raffle/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Raffles.create_raffle(@invalid_attrs)
    end
  end
end
