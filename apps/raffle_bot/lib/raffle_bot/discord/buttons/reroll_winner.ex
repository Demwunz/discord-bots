defmodule RaffleBot.Discord.Buttons.RerollWinner do
  @moduledoc """
  Handles the "Re-Roll" button for winner selection.

  Opens a modal to collect the reason for re-rolling, then
  logs the re-roll and picks a new winner.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction

  def handle(%Interaction{data: %{"custom_id" => "reroll_winner_" <> rest}} = interaction) do
    [raffle_id, previous_winner_id] = String.split(rest, "_", parts: 2)

    # Show modal for re-roll reason
    modal = %{
      title: "Re-Roll Reason",
      custom_id: "reroll_reason_modal_#{raffle_id}_#{previous_winner_id}",
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 4,  # Text input
              custom_id: "reroll_reason",
              label: "Why are you re-rolling this winner?",
              style: 2,  # Paragraph
              placeholder: "Required - for transparency and audit purposes",
              required: true,
              min_length: 5,
              max_length: 500
            }
          ]
        }
      ]
    }

    discord_api().create_interaction_response(interaction, 9, modal)
  end
end
