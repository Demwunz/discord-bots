defmodule RaffleBot.Discord.Selects.MarkPaidRaffle do
  @moduledoc """
  Handles the selection of a raffle to mark users as paid.
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Claims
  alias Nostrum.Struct.Component.{ActionRow, SelectMenu}

  def handle(%Interaction{data: %{"values" => [raffle_id]}} = interaction) do
    claims = Claims.get_claims_by_raffle(raffle_id)

    # TODO: Get user names from user_ids
    options =
      claims
      |> Enum.reject(& &1.is_paid)
      |> Enum.map(fn claim ->
        %{
          label: to_string(claim.user_id),
          value: claim.id
        }
      end)

    select_menu = %SelectMenu{
      custom_id: "mark_paid_user_select",
      placeholder: "Select users to mark as paid",
      options: options,
      min_values: 1,
      max_values: length(options)
    }

    Api.create_interaction_response(interaction, %{
      type: 4,
      data: %{
        content: "Please select the users to mark as paid.",
        components: [%ActionRow{components: [select_menu]}],
        flags: 64
      }
    })
  end
end
