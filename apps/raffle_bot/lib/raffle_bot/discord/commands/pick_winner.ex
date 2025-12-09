defmodule RaffleBot.Discord.Commands.PickWinner do
  @moduledoc """
  Handles the /pick_winner command
  """

  alias Nostrum.Api
  alias RaffleBot.Raffles

  def handle(interaction) do
    raffles = Raffles.list_closed_raffles()

    options =
      Enum.map(raffles, fn raffle ->
        %{
          label: raffle.title,
          value: raffle.id
        }
      end)

    select_menu = %{
      type: 3,
      custom_id: "pick_winner_select",
      placeholder: "Select a raffle",
      options: options
    }

    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "Please select a raffle to pick a winner from.",
        components: [%{type: 1, components: [select_menu]}],
        flags: 64
      }
    })
  end
end
