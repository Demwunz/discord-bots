defmodule RaffleBot.Discord.Selects.ClaimSpot do
  @moduledoc """
  Handles the selection of a spot to claim.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Claims

  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed
  alias RaffleBot.Raffles

  def handle(%Interaction{data: %{"values" => spots, "custom_id" => "claim_spot_select_" <> raffle_id}, member: %{user: %{id: user_id}}} = interaction) do
    raffle = Raffles.get_raffle!(raffle_id)

    for spot <- spots do
      Claims.create_claim(%{
        raffle_id: raffle.id,
        user_id: user_id,
        spot_number: spot
      })
    end

    claims = Claims.get_claims_by_raffle(raffle.id)

    if length(claims) == raffle.total_spots do
      admin_channel_id = Application.get_env(:raffle_bot, :admin_channel_id)
      message = "🚨 SOLD OUT: #{raffle.title}"
      discord_api().create_message(admin_channel_id, message)
      Raffles.close_raffle(raffle)
    end

    discord_api().edit_interaction_response(interaction, %{
      embeds: [RaffleEmbed.build(raffle, claims)],
      components: RaffleEmbed.components(raffle, claims)
    })
  end
end
