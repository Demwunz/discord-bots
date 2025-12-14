defmodule RaffleBot.Discord.Helpers.ButtonRefresher do
  @moduledoc """
  Helper module for refreshing raffle spot button messages.

  This module handles updating all button messages when claims change,
  including multi-page raffles with >20 spots (20 spots per page + utility row).
  """

  use RaffleBot.Discord.ApiConsumer
  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed

  @doc """
  Refreshes all button messages for a raffle.

  This updates:
  - The first message (page 1, spots 1-20 + utility row)
  - All additional messages (pages 2+, spots 21+)

  Used after:
  - A user claims a spot
  - An admin marks spots as paid
  - Payment status changes

  ## Parameters

    * `raffle_id` - The ID of the raffle to refresh

  ## Examples

      refresh_raffle_buttons("raffle_123")
  """
  def refresh_raffle_buttons(raffle_id) do
    raffle = Raffles.get_raffle!(raffle_id)
    claims = Claims.get_claims_by_raffle(raffle_id)

    # Update starter message (page 1)
    buttons_page_1 = RaffleEmbed.build_spot_buttons(raffle, claims, 1)

    discord_api().edit_message(
      raffle.channel_id,
      raffle.message_id,
      %{components: buttons_page_1}
    )

    # Update additional messages (pages 2+)
    raffle.spot_button_message_ids
    |> Enum.with_index(2)
    |> Enum.each(fn {message_id, page} ->
      buttons = RaffleEmbed.build_spot_buttons(raffle, claims, page)
      discord_api().edit_message(raffle.channel_id, message_id, %{components: buttons})
    end)
  end
end
