defmodule RaffleBot.Discord.Selects.ExtendRaffle do
  @moduledoc """
  Handles the selection of a raffle to extend.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles

  alias RaffleBot.Closer

  def handle(%Interaction{data: %{"values" => [raffle_id]}} = interaction) do
    raffle = Raffles.get_raffle!(raffle_id)

    new_auto_close_at =
      raffle.auto_close_at
      |> DateTime.add(7 * 86400, :second) # 86400 seconds in a day

    {:ok, updated_raffle} = Raffles.update_raffle(raffle, %{auto_close_at: new_auto_close_at})

    Closer.schedule_close(updated_raffle)

    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: "Raffle #{raffle.title} has been extended by 7 days.",
        flags: 64
      }
    )
  end
end
