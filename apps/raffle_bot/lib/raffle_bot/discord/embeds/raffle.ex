defmodule RaffleBot.Discord.Embeds.Raffle do
  @moduledoc """
  Handles the creation of the raffle embed.
  """

  alias Nostrum.Struct.Embed
  alias RaffleBot.Raffles.Raffle

  def build(%Raffle{} = raffle, claims) do
    spots_claimed = length(claims)
    spots_remaining = raffle.total_spots - spots_claimed
    participants = Enum.map(claims, &" <@#{&1.user_id}>") |> Enum.join(", ")

    %Embed{
      title: "Raffle Time!",
      description: raffle.description,
      color: 0x57F287,
      fields: [
        %{name: "Title", value: raffle.title, inline: true},
        %{name: "Price", value: to_string(raffle.price), inline: true},
        %{name: "Total Spots", value: to_string(raffle.total_spots), inline: true},
        %{name: "Spots Claimed", value: to_string(spots_claimed), inline: true},
        %{name: "Spots Remaining", value: to_string(spots_remaining), inline: true},
        %{name: "Participants", value: participants}
      ]
    }
  end

  def components(%Raffle{} = raffle, claims) do
    spots_claimed = length(claims)

    if spots_claimed >= raffle.total_spots do
      []
    else
      [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 1,
              label: "🎟️ Claim Spots",
              custom_id: "claim_spots_#{raffle.id}"
            }
          ]
        }
      ]
    end
  end
end
