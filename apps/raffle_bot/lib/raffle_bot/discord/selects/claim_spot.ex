defmodule RaffleBot.Discord.Selects.ClaimSpot do
  @moduledoc """
  Handles the selection of a spot to claim.
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Claims

  def handle(%Interaction{data: %{"values" => spots, "custom_id" => "claim_spot_select_" <> raffle_id}, member: %{user: %{id: user_id}}} = interaction) do
    for spot <- spots do
      Claims.create_claim(%{
        raffle_id: raffle_id,
        user_id: user_id,
        spot_number: spot
      })
    end

    # TODO: Update the raffle embed
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "You have successfully claimed your spots!",
        flags: 64
      }
    })
  end
end
