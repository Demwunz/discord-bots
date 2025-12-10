defmodule RaffleBot.Discord.Selects.MarkPaidRaffle do
  @moduledoc """
  Handles the selection of a raffle to mark users as paid.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Claims

  def handle(%Interaction{data: %{"values" => [raffle_id]}} = interaction) do
    claims = Claims.get_claims_by_raffle(raffle_id)

    options =
      claims
      |> Enum.reject(& &1.is_paid)
      |> Enum.map(fn claim ->
        with {:ok, user} <- discord_api().get_user(claim.user_id) do
          %{
            label: user.username,
            value: claim.id
          }
        end
      end)

    select_menu = %{
      type: 3,
      custom_id: "mark_paid_user_select",
      placeholder: "Select users to mark as paid",
      options: options,
      min_values: 1,
      max_values: length(options)
    }

    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: "Please select the users to mark as paid.",
        components: [%{type: 1, components: [select_menu]}],
        flags: 64
      }
    )
  end
end
