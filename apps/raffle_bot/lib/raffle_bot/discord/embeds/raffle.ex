defmodule RaffleBot.Discord.Embeds.Raffle do
  @moduledoc """
  Handles the creation of the raffle embed.
  """

  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Component.{ActionRow, Button}
  alias RaffleBot.Raffles.Raffle

  def build(%Raffle{} = raffle) do
    %Embed{
      title: "Raffle Time!",
      description: raffle.description,
      color: 0x57F287,
      fields: [
        %{name: "Title", value: raffle.title, inline: true},
        %{name: "Price", value: to_string(raffle.price), inline: true},
        %{name: "Total Spots", value: to_string(raffle.total_spots), inline: true}
      ]
    }
  end

  def components(%Raffle{}) do
    [
      %ActionRow{
        components: [
          %Button{
            custom_id: "claim_spots",
            label: "🎟️ Claim Spots",
            style: :primary
          }
        ]
      }
    ]
  end
end
