defmodule RaffleBot.Discord.Buttons.ClaimSpots do
  @moduledoc """
  Handles the 'Claim Spots' button press.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims

  def handle(%Interaction{message: %{id: message_id}} = interaction) do
    raffle = Raffles.get_raffle_by_message_id(message_id)

    claims = Claims.get_claims_by_raffle(raffle.id)
    claimed_spots = Enum.map(claims, & &1.spot_number)
    all_spots = 1..raffle.total_spots
    available_spots = all_spots -- claimed_spots

    components =
      available_spots
      |> Enum.chunk_every(25)
      |> Enum.map(fn chunk ->
        options =
          Enum.map(chunk, fn spot ->
            %{
              label: "Spot ##{spot}",
              value: spot
            }
          end)

        %{
          type: 1,
          components: [
            %{
              type: 3,
              custom_id: "claim_spot_select_#{raffle.id}",
              placeholder: "Select your spots (#{Enum.min(chunk)}-#{Enum.max(chunk)})",
              options: options,
              min_values: 1,
              max_values: length(options)
            }
          ]
        }
      end)

    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: "Please select your spots.",
        components: components,
        flags: 64
      }
    )
  end
end
