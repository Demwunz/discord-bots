defmodule RaffleBot.Discord.Buttons.MarkSelfPaid do
  @moduledoc """
  Handles user self-marking their spots as paid.

  Shows a payment platform select menu, then collects username via modal.
  Updates claims to user_marked_paid = true, refreshes buttons,
  and sends notification to both raffle thread and admin thread.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims

  def handle(%Interaction{data: %{"custom_id" => "mark_self_paid_" <> raffle_id}} = interaction) do
    user_id = interaction.user.id
    raffle = Raffles.get_raffle!(raffle_id)
    user_claims = Claims.get_user_claims_for_raffle(user_id, raffle_id)

    if length(user_claims) == 0 do
      # User has no claims
      discord_api().create_interaction_response(
        interaction,
        4,
        %{
          content: "❌ You don't have any spots claimed in this raffle.",
          flags: 64
        }
      )
    else
      # Check if already marked as paid
      already_paid = Enum.any?(user_claims, & &1.user_marked_paid)

      if already_paid do
        discord_api().create_interaction_response(
          interaction,
          4,
          %{
            content: "✅ You've already marked your spots as paid. An admin will verify your payment soon.",
            flags: 64
          }
        )
      else
        # Calculate total for display
        total_amount = length(user_claims) * raffle.price
        spot_count = length(user_claims)

        # Show payment platform select menu
        discord_api().create_interaction_response(
          interaction,
          4,
          %{
            content: """
            💳 **Select Payment Method**

            You're marking **#{spot_count} spot(s)** as paid — **$#{total_amount}** total.

            Which platform did you use to pay?
            """,
            components: [
              %{
                type: 1,
                components: [
                  %{
                    type: 3,
                    custom_id: "payment_platform_select_#{raffle_id}",
                    placeholder: "Select payment platform...",
                    options: [
                      %{label: "Venmo", value: "venmo", emoji: %{name: "💜"}},
                      %{label: "PayPal", value: "paypal", emoji: %{name: "💙"}},
                      %{label: "Zelle", value: "zelle", emoji: %{name: "💚"}}
                    ]
                  }
                ]
              }
            ],
            flags: 64
          }
        )
      end
    end
  end
end
