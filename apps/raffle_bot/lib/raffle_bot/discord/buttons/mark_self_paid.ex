defmodule RaffleBot.Discord.Buttons.MarkSelfPaid do
  @moduledoc """
  Handles user self-marking their spots as paid.

  Updates claims to user_marked_paid = true, refreshes buttons,
  and sends notification to admin thread for verification.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Helpers.ButtonRefresher

  def handle(%Interaction{data: %{"custom_id" => "mark_self_paid_" <> raffle_id}} = interaction) do
    user_id = interaction.user.id
    raffle = Raffles.get_raffle!(raffle_id)
    user_claims = Claims.get_user_claims_for_raffle(user_id, raffle_id)

    if length(user_claims) == 0 do
      # User has no claims
      discord_api().edit_interaction_response(
        interaction,
        %{
          content: "❌ You don't have any spots claimed in this raffle.",
          components: []
        }
      )
    else
      # Update all user's claims to marked as paid
      Enum.each(user_claims, fn claim ->
        Claims.update_claim(claim, %{
          user_marked_paid: true,
          user_marked_paid_at: DateTime.utc_now()
        })
      end)

      # Refresh raffle buttons to show pending payment status
      ButtonRefresher.refresh_raffle_buttons(raffle_id)

      # Send notification to admin thread
      send_admin_notification(raffle, user_id, user_claims)

      # Calculate total
      total_amount = length(user_claims) * raffle.price
      spot_numbers = Enum.map(user_claims, & &1.spot_number) |> Enum.sort()
      spot_list = format_spot_list(spot_numbers)

      # Update ephemeral response
      discord_api().edit_interaction_response(
        interaction,
        %{
          content: """
          ✅ **Marked as Paid**

          Your payment for #{spot_list} ($#{total_amount}) has been marked.
          An admin will verify your payment and update the raffle.

          Thank you!
          """,
          components: []
        }
      )
    end
  end

  defp send_admin_notification(raffle, user_id, user_claims) do
    if raffle.admin_thread_id do
      total_amount = length(user_claims) * raffle.price
      spot_numbers = Enum.map(user_claims, & &1.spot_number) |> Enum.sort()
      spot_list = format_spot_list(spot_numbers)

      content = """
      💵 **Payment Marked by User**

      <@#{user_id}> marked their spots as paid:
      **Spots:** #{spot_list}
      **Amount:** $#{total_amount}

      Please verify payment and confirm below.
      """

      components = [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 3,
              label: "✅ Confirm Payment",
              custom_id: "admin_confirm_payment_#{raffle.id}_#{user_id}"
            },
            %{
              type: 2,
              style: 4,
              label: "❌ Reject",
              custom_id: "admin_reject_payment_#{raffle.id}_#{user_id}"
            }
          ]
        }
      ]

      discord_api().create_message(
        raffle.admin_thread_id,
        "",
        [
          content: content,
          components: components
        ]
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
