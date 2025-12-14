defmodule RaffleBot.Discord.Buttons.ConfirmClaim do
  @moduledoc """
  Handles the confirmation of a spot claim.
  Creates the claim in the database and refreshes all spot button messages.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Helpers.ButtonRefresher

  def handle(%Interaction{data: %{"custom_id" => "confirm_claim_" <> rest}} = interaction) do
    [raffle_id, spot_number_str] = String.split(rest, "_", parts: 2)
    spot_number = String.to_integer(spot_number_str)
    user_id = interaction.user.id

    case Claims.create_claim(%{
           raffle_id: raffle_id,
           user_id: user_id,
           spot_number: spot_number,
           is_paid: false
         }) do
      {:ok, _claim} ->
        # Refresh all button messages for this raffle
        ButtonRefresher.refresh_raffle_buttons(raffle_id)

        # Check if raffle is now sold out
        raffle = Raffles.get_raffle!(raffle_id)
        claims = Claims.get_claims_by_raffle(raffle_id)

        if length(claims) == raffle.total_spots do
          # Raffle is sold out - post payment button
          post_payment_message(raffle)
        end

        # Update ephemeral response
        discord_api().edit_interaction_response(
          interaction,
          %{
            content: "✅ **Spot Claimed!**\n\nYou've claimed spot ##{spot_number}.",
            components: []
          }
        )

      {:error, changeset} ->
        error_msg =
          if changeset.errors[:spot_number] do
            "❌ **Spot Unavailable**\n\nSpot ##{spot_number} was just claimed. Try another spot."
          else
            "❌ **Error**: Unable to claim spot. Please try again."
          end

        discord_api().edit_interaction_response(
          interaction,
          %{
            content: error_msg,
            components: []
          }
        )
    end
  end

  defp post_payment_message(raffle) do
    content = """
    🎉 **All Spots Claimed!**

    This raffle is now full! If you claimed spots, please proceed with payment.

    Click the button below to view payment details and mark your spots as paid.
    """

    components = [
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 1,
            label: "💰 Pay for Your Spots",
            custom_id: "payment_info_#{raffle.id}"
          }
        ]
      }
    ]

    discord_api().create_message(
      raffle.channel_id,
      "",
      [
        content: content,
        components: components
      ]
    )
  end
end
