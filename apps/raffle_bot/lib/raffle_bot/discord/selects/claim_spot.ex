defmodule RaffleBot.Discord.Selects.ClaimSpot do
  @moduledoc """
  Handles the selection of a spot to claim.
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Claims

  def handle(interaction) do
    # TODO: Create the claims and update the raffle embed
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "You have successfully claimed your spots!",
        flags: 64
      }
    })
  end
end
