defmodule RaffleBot.Discord.Buttons.ConfirmClaim do
  @moduledoc """
  Handles the confirmation of a spot claim.
  Creates the claim in the database and refreshes all spot button messages.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed

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
        refresh_raffle_buttons(raffle_id)

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

  @doc """
  Refreshes all button messages for a raffle after a claim is made.
  Updates the first message and all additional button messages.
  """
  defp refresh_raffle_buttons(raffle_id) do
    raffle = Raffles.get_raffle!(raffle_id)
    claims = Claims.get_claims_by_raffle(raffle_id)

    # Update starter message (page 1)
    buttons_page_1 = RaffleEmbed.build_spot_buttons(raffle, claims, 1)

    discord_api().edit_message(
      raffle.channel_id,
      raffle.message_id,
      %{components: buttons_page_1}
    )

    # Update additional messages (pages 2+)
    raffle.spot_button_message_ids
    |> Enum.with_index(2)
    |> Enum.each(fn {message_id, page} ->
      buttons = RaffleEmbed.build_spot_buttons(raffle, claims, page)
      discord_api().edit_message(raffle.channel_id, message_id, %{components: buttons})
    end)
  end
end
