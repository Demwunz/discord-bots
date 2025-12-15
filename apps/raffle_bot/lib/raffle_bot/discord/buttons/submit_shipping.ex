defmodule RaffleBot.Discord.Buttons.SubmitShipping do
  @moduledoc """
  Handles the "Submit Shipping Details" button for winners.

  Validates that the user clicking is the winner, then shows
  the shipping details modal.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles

  def handle(%Interaction{data: %{"custom_id" => "submit_shipping_" <> rest}} = interaction) do
    [raffle_id, winner_id] = String.split(rest, "_", parts: 2)
    user_id = to_string(interaction.user.id)

    raffle = Raffles.get_raffle!(raffle_id)

    cond do
      user_id != winner_id ->
        discord_api().create_interaction_response(interaction, 4, %{
          content: "❌ This button is only for the winner.",
          flags: 64
        })

      raffle.shipping_submitted_at != nil ->
        discord_api().create_interaction_response(interaction, 4, %{
          content: "✅ You've already submitted your shipping details. The admin has been notified.",
          flags: 64
        })

      true ->
        show_shipping_modal(interaction, raffle_id)
    end
  end

  defp show_shipping_modal(interaction, raffle_id) do
    modal = %{
      title: "Shipping Details",
      custom_id: "shipping_details_modal_#{raffle_id}",
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "shipping_name",
              label: "Full Name",
              style: 1,  # Short
              placeholder: "John Doe",
              required: true,
              max_length: 100
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "shipping_address",
              label: "Street Address",
              style: 2,  # Paragraph
              placeholder: "123 Main St\nApt 4B",
              required: true,
              max_length: 200
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "shipping_city_state_zip",
              label: "City, State, ZIP",
              style: 1,
              placeholder: "New York, NY 10001",
              required: true,
              max_length: 100
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "shipping_country",
              label: "Country",
              style: 1,
              placeholder: "United States",
              required: true,
              max_length: 50
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "shipping_phone",
              label: "Phone Number (Optional)",
              style: 1,
              placeholder: "+1 (555) 123-4567",
              required: false,
              max_length: 30
            }
          ]
        }
      ]
    }

    discord_api().create_interaction_response(interaction, 9, modal)
  end
end
