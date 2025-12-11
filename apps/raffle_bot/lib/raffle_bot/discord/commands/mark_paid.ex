defmodule RaffleBot.Discord.Commands.MarkPaid do
  @moduledoc """
  Handles the /mark_paid command
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
      custom_id: "mark_paid_raffle_select",
      placeholder: "Select a raffle",
      options: options
    }

    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: "Please select a raffle to mark users as paid.",
        components: [%{type: 1, components: [select_menu]}],
        flags: 64
      }
    )
  end
end
