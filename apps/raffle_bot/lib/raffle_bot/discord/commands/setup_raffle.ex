defmodule RaffleBot.Discord.Commands.SetupRaffle do
  @moduledoc """
  Handles the /setup_raffle command
  """

  alias Nostrum.Api

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
              required: true
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "price",
              label: "Price",
              style: 1,
              required: true
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
              required: true
            }
          ]
        },
        %{
          type: 1,
          components: [
            %{
              type: 4,
              custom_id: "photo_url",
              label: "Photo URL",
              style: 1,
              required: true
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
              required: true
            }
          ]
        }
      ]
    }

    Api.create_interaction_response(interaction, %{
      type: 9,
      data: modal
    })
  end
end
