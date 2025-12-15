defmodule RaffleBot.Discord.Modals.PaymentConfirm do
  @moduledoc """
  Handles payment confirmation modal submission.

  Updates all user's claims to marked as paid, refreshes buttons,
  sends notification to raffle thread (public) and admin thread (with buttons).
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Helpers.ButtonRefresher

  def handle(
        %Interaction{
          data: %{
            "custom_id" => "payment_confirm_modal_" <> rest,
            "components" => components
          }
        } = interaction
      ) do
    # Parse raffle_id and platform from custom_id
    [raffle_id, platform] = String.split(rest, "_", parts: 2)

    # Extract username from modal
    payment_username = extract_username(components)

    user_id = interaction.user.id
    raffle = Raffles.get_raffle!(raffle_id)
    user_claims = Claims.get_user_claims_for_raffle(user_id, raffle_id)

    if length(user_claims) == 0 do
      discord_api().create_interaction_response(
        interaction,
        4,
        %{
          content: "❌ You don't have any spots claimed in this raffle.",
          flags: 64
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

      # Calculate totals
      total_amount = length(user_claims) * raffle.price
      spot_numbers = Enum.map(user_claims, & &1.spot_number) |> Enum.sort()
      spot_list = format_spot_list(spot_numbers)
      platform_label = platform_display_name(platform)

      # Send admin notification with confirm/reject buttons (no public notification - buttons show status)
      send_admin_notification(raffle, user_id, spot_list, total_amount, platform_label, payment_username)

      # Send confirmation to user
      discord_api().create_interaction_response(
        interaction,
        4,
        %{
          content: """
          ✅ **Payment Marked!**

          Your payment for #{spot_list} (**$#{total_amount}**) has been recorded.
          **Platform:** #{platform_label}
          **Username:** #{payment_username}

          An admin will verify your payment and update the raffle.
          Thank you!
          """,
          flags: 64
        }
      )
    end
  end

  defp extract_username(components) do
    components
    |> Enum.flat_map(fn %{"components" => inner} -> inner end)
    |> Enum.find(fn %{"custom_id" => id} -> id == "payment_username" end)
    |> Map.get("value", "")
  end

  defp send_admin_notification(raffle, user_id, spot_list, total_amount, platform_label, payment_username) do
    if raffle.admin_thread_id do
      content = """
      💸 Spots #{spot_list} claimed by <@#{user_id}> marked paid
      **#{platform_label}:** `#{payment_username}` • **$#{total_amount}**
      """

      components = [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 3,
              label: "Confirmed",
              custom_id: "admin_confirm_payment_#{raffle.id}_#{user_id}"
            },
            %{
              type: 2,
              style: 4,
              label: "Unconfirmed",
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

  defp platform_display_name("venmo"), do: "Venmo"
  defp platform_display_name("paypal"), do: "PayPal"
  defp platform_display_name("zelle"), do: "Zelle"
  defp platform_display_name(_), do: "Unknown"
end
