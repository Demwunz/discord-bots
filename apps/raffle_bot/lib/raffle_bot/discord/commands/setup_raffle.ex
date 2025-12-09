defmodule RaffleBot.Discord.Commands.SetupRaffle do
  @moduledoc """
  Handles the /setup_raffle command
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias Nostrum.Struct.Component.{ActionRow, TextInput}

  def handle(interaction) do
    modal = %{
      title: "Raffle Setup",
      custom_id: "raffle_setup_modal",
      components: [
        %ActionRow{
          components: [
            %TextInput{
              custom_id: "title",
              label: "Title",
              style: :short,
              required: true
            }
          ]
        },
        %ActionRow{
          components: [
            %TextInput{
              custom_id: "price",
              label: "Price",
              style: :short,
              required: true
            }
          ]
        },
        %ActionRow{
          components: [
            %TextInput{
              custom_id: "total_spots",
              label: "Total Spots",
              style: :short,
              required: true
            }
          ]
        },
        %ActionRow{
          components: [
            %TextInput{
              custom_id: "photo_url",
              label: "Photo URL",
              style: :short,
              required: true
            }
          ]
        },
        %ActionRow{
          components: [
            %TextInput{
              custom_id: "description",
              label: "Description",
              style: :paragraph,
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
