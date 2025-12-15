defmodule RaffleBot.Discord.Selects.PaymentPlatform do
  @moduledoc """
  Handles payment platform selection.

  When user selects a platform (Venmo/PayPal/Zelle), opens a modal
  to collect their username for that platform.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction

  def handle(
        %Interaction{
          data: %{
            "custom_id" => "payment_platform_select_" <> raffle_id,
            "values" => [platform]
          }
        } = interaction
      ) do
    platform_label = platform_display_name(platform)
    placeholder = platform_placeholder(platform)

    # Open modal to collect username
    modal = %{
      title: "Confirm Payment",
      custom_id: "payment_confirm_modal_#{raffle_id}_#{platform}",
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "payment_username",
              label: "Your #{platform_label} username/email",
              style: 1,
              required: true,
              placeholder: placeholder,
              min_length: 3,
              max_length: 100
            }
          ]
        }
      ]
    }

    discord_api().create_interaction_response(interaction, 9, modal)
  end

  defp platform_display_name("venmo"), do: "Venmo"
  defp platform_display_name("paypal"), do: "PayPal"
  defp platform_display_name("zelle"), do: "Zelle"
  defp platform_display_name(_), do: "Payment"

  defp platform_placeholder("venmo"), do: "@username"
  defp platform_placeholder("paypal"), do: "email@example.com"
  defp platform_placeholder("zelle"), do: "email or phone"
  defp platform_placeholder(_), do: "username or email"
end
