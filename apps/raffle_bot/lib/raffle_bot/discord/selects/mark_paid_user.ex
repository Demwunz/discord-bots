defmodule RaffleBot.Discord.Selects.MarkPaidUser do
  @moduledoc """
  Handles the selection of users to mark as paid.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Claims

  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed
  alias RaffleBot.Raffles

  def handle(%Interaction{data: %{"values" => claim_ids}} = interaction) do
    for claim_id <- claim_ids do
      claim = Claims.get_claim!(claim_id)
      {:ok, _} = Claims.update_claim(claim, %{is_paid: true})
    end

    # All claims are for the same raffle, so we can just grab the first one
    # to get the raffle id.
    raffle_id =
      claim_ids
      |> List.first()
      |> Claims.get_claim!()
      |> Map.get(:raffle_id)

    raffle = Raffles.get_raffle!(raffle_id)
    claims = Claims.get_claims_by_raffle(raffle_id)

    discord_api().edit_interaction_response(interaction, %{
      embeds: [RaffleEmbed.build(raffle, claims)],
      components: RaffleEmbed.components(raffle, claims)
    })
  end
end
