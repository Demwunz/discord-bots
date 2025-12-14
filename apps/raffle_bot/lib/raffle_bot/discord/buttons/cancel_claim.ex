defmodule RaffleBot.Discord.Buttons.CancelClaim do
  @moduledoc """
  Handles cancellation of a spot claim confirmation dialog.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction

  def handle(%Interaction{} = interaction) do
    discord_api().edit_interaction_response(
      interaction,
      %{
        content: "Claim cancelled.",
        components: []
      }
    )
  end
end
