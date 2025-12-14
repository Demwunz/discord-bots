defmodule RaffleBot.Discord.Buttons.PaymentInfo do
  @moduledoc """
  Shows payment details and allows users to mark their spots as paid.
  Displayed when user clicks "Pay for your spots" button.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims

  def handle(%Interaction{data: %{"custom_id" => "payment_info_" <> raffle_id}} = interaction) do
    user_id = interaction.user.id
    raffle = Raffles.get_raffle!(raffle_id)
    user_claims = Claims.get_user_claims_for_raffle(user_id, raffle_id)

    if length(user_claims) == 0 do
      # User has no claims in this raffle
      discord_api().create_interaction_response(
        interaction,
        4,
        %{
          content: "❌ You don't have any spots claimed in this raffle.",
          flags: 64
        }
      )
    else
      # Calculate total amount
      spot_numbers = Enum.map(user_claims, & &1.spot_number) |> Enum.sort()
      total_amount = length(user_claims) * raffle.price

      # Check if any are already marked as paid
      already_paid = Enum.any?(user_claims, & &1.user_marked_paid)

      payment_details =
        if raffle.payment_details && raffle.payment_details != "" do
          raffle.payment_details
        else
          "Contact the raffle admin for payment details."
        end

      spot_list = format_spot_list(spot_numbers)

      content = """
      🎟️ **Payment Information**

      **Raffle:** #{raffle.title}
      **Your Spots:** #{spot_list}
      **Total Amount:** $#{total_amount} ($#{raffle.price} per spot)

      **Payment Details:**
      #{payment_details}

      Once you've completed payment, click "Mark as Paid" below.
      An admin will verify your payment.
      """

      components =
        if already_paid do
          []
        else
          [
            %{
              type: 1,
              components: [
                %{
                  type: 2,
                  style: 3,
                  label: "✅ Mark as Paid",
                  custom_id: "mark_self_paid_#{raffle_id}"
                }
              ]
            }
          ]
        end

      discord_api().create_interaction_response(
        interaction,
        4,
        %{
          content: content,
          components: components,
          flags: 64
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
