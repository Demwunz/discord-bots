defmodule RaffleBot.Discord.Commands.ExtendRaffle do
  @moduledoc """
  Handles the /extend_raffle command
  """

  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.Raffles

  def handle(interaction) do
    raffles = Raffles.list_active_raffles()

    options =
      Enum.map(raffles, fn raffle ->
        %{
          label: raffle.title,
          value: raffle.id
        }
      end)

    select_menu = %{
      type: 3,
      custom_id: "extend_raffle_select",
      placeholder: "Select a raffle to extend",
      options: options
    }

    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: "Please select a raffle to extend by 7 days.",
        components: [%{type: 1, components: [select_menu]}],
        flags: 64
      }
    )
  end
end
