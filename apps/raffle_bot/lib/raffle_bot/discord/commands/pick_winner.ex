defmodule RaffleBot.Discord.Commands.PickWinner do
  @moduledoc """
  Handles the /pick_winner command
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles

  def handle(interaction) do
    # TODO: Fetch closed raffles and present them in a dropdown
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "Please select a raffle to pick a winner from.",
        flags: 64
      }
    })
  end
end
