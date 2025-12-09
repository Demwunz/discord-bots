defmodule RaffleBot.Discord.Selects.MarkPaidUser do
  @moduledoc """
  Handles the selection of users to mark as paid.
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Claims

  def handle(%Interaction{data: %{"values" => claim_ids}} = interaction) do
    for claim_id <- claim_ids do
      # This is not efficient, but it's fine for now.
      # A better approach would be to have a `get_claim!/1` and `update_claim/2`
      # that takes attrs, so we can do this in one query.
      {:ok, claim} = Claims.get_claim!(claim_id)
      Claims.update_claim(claim, %{is_paid: true})
    end

    # TODO: Update the raffle embed
    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "Users have been marked as paid.",
        flags: 64
      }
    })
  end
end
