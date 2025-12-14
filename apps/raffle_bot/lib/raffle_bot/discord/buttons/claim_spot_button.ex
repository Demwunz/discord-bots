defmodule RaffleBot.Discord.Buttons.ClaimSpotButton do
  @moduledoc """
  Handles individual spot button press (new per-spot button UI).
  Shows confirmation dialog before claiming.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles

  def handle(%Interaction{data: %{"custom_id" => "claim_spot_" <> rest}} = interaction) do
    [raffle_id, spot_number_str] = String.split(rest, "_", parts: 2)
    spot_number = String.to_integer(spot_number_str)

    raffle = Raffles.get_raffle!(raffle_id)

    # Show confirmation dialog (ephemeral)
    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: """
        🎟️ **Confirm Claim**

        Spot: **##{spot_number}**
        Raffle: **#{raffle.title}**
        Price: **$#{raffle.price}**

        Click "Confirm" to claim this spot.
        """,
        components: [
          %{
            type: 1,
            components: [
              %{
                type: 2,
                style: 3,  # Green
                label: "✅ Confirm Claim",
                custom_id: "confirm_claim_#{raffle_id}_#{spot_number}"
              },
              %{
                type: 2,
                style: 4,  # Red
                label: "❌ Cancel",
                custom_id: "cancel_claim"
              }
            ]
          }
        ],
        flags: 64  # Ephemeral
      }
    )
  end
end
