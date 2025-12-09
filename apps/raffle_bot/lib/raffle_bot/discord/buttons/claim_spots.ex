defmodule RaffleBot.Discord.Buttons.ClaimSpots do
  @moduledoc """
  Handles the 'Claim Spots' button press.
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias Nostrum.Struct.Component.{ActionRow, SelectMenu}

  def handle(%Interaction{message: %{id: message_id}} = interaction) do
    # This is not ideal. We should add a `get_raffle_by_message_id/1` to the Raffles context.
    raffle =
      Raffles.list_raffles()
      |> Enum.find(&(&1.message_id == message_id))

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

        %ActionRow{
          components: [
            %SelectMenu{
              custom_id: "claim_spot_select_#{raffle.id}",
              placeholder: "Select your spots (#{Enum.min(chunk)}-#{Enum.max(chunk)})",
              options: options,
              min_values: 1,
              max_values: length(options)
            }
          ]
        }
      end)

    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "Please select your spots.",
        components: components,
        flags: 64
      }
    })
  end
end
