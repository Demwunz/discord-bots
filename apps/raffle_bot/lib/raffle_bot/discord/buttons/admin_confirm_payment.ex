defmodule RaffleBot.Discord.Buttons.AdminConfirmPayment do
  @moduledoc """
  Handles admin confirmation of user payment.

  Sets is_paid = true for user's claims and refreshes buttons to green.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Helpers.ButtonRefresher

  def handle(
        %Interaction{data: %{"custom_id" => "admin_confirm_payment_" <> rest}} = interaction
      ) do
    [raffle_id, user_id_str] = String.split(rest, "_", parts: 2)
    user_id = String.to_integer(user_id_str)

    raffle = Raffles.get_raffle!(raffle_id)
    user_claims = Claims.get_user_claims_for_raffle(user_id, raffle_id)

    if length(user_claims) == 0 do
      # No claims found
      discord_api().create_interaction_response(
        interaction,
        4,
        %{
          content: "❌ No claims found for this user.",
          flags: 64
        }
      )
    else
      # Update all user's claims to fully paid
      Enum.each(user_claims, fn claim ->
        Claims.update_claim(claim, %{is_paid: true})
      end)

      # Refresh raffle buttons to show confirmed payment (green)
      ButtonRefresher.refresh_raffle_buttons(raffle_id)

      # Calculate details
      total_amount = length(user_claims) * raffle.price
      spot_numbers = Enum.map(user_claims, & &1.spot_number) |> Enum.sort()
      spot_list = format_spot_list(spot_numbers)

      # Update the message to show confirmation
      discord_api().edit_interaction_response(
        interaction,
        %{
          content: """
          ✅ **Payment Confirmed**

          <@#{user_id}>'s payment has been confirmed:
          **Spots:** #{spot_list}
          **Amount:** $#{total_amount}

          Buttons updated to show confirmed payment.
          """,
          components: []
        }
      )
    end
  end

  defp format_spot_list(spots) when length(spots) <= 5 do
    Enum.map_join(spots, ", ", &"##{&1}")
  end

  defp format_spot_list(spots) do
    "#{length(spots)} spots (##{Enum.min(spots)}-##{Enum.max(spots)})"
  end
end
