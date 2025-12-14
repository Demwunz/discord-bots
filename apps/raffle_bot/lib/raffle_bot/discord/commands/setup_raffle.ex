defmodule RaffleBot.Discord.Commands.SetupRaffle do
  @moduledoc """
  Handles the /setup_raffle command.

  Uses a modal for text fields. Photos are uploaded separately via the
  admin thread after raffle creation.
  """

  use RaffleBot.Discord.ApiConsumer

  def handle(interaction) do
    modal = %{
      title: "Raffle Setup",
      custom_id: "raffle_setup_modal",
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "title",
              label: "Title",
              style: 1,
              required: true,
              placeholder: "e.g., Spawn #1 CGC 9.8"
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "price",
              label: "Price per Spot",
              style: 1,
              required: true,
              placeholder: "e.g., 10"
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "total_spots",
              label: "Total Spots",
              style: 1,
              required: true,
              placeholder: "e.g., 25"
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "payment_details",
              label: "Payment Details",
              style: 1,
              required: false,
              placeholder: "e.g., Venmo: @username, PayPal: email@example.com"
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "description",
              label: "Description",
              style: 2,
              required: true,
              placeholder: "Describe the item being raffled..."
            }
          ]
        }
      ]
    }

    discord_api().create_interaction_response(interaction, 9, modal)
  end
end
