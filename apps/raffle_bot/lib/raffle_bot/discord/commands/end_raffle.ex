defmodule RaffleBot.Discord.Commands.EndRaffle do
  @moduledoc """
  Handles the /end_raffle command
  """

  alias Nostrum.Api
  def handle(interaction) do
    # TODO: Fetch active raffles and present them in a dropdown
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "Please select a raffle to end.",
        flags: 64
      }
    })
  end
end
