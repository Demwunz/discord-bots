defmodule RaffleBot.Discord.Buttons.ControlPanelListRaffles do
  @moduledoc """
  Handles the "List Active Raffles" button in the Control Panel.

  Returns an ephemeral embed showing all active raffles.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Discord.Components.ControlPanel

  def handle(%Interaction{} = interaction) do
    # Get all active raffles
    active_raffles = Raffles.list_active_raffles()

    # Build the embed
    embed = ControlPanel.build_active_raffles_embed(active_raffles)

    # Send ephemeral response
    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        embeds: [embed],
        flags: 64
      }
    )
  end
end
