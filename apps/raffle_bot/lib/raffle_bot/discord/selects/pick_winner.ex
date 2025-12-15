defmodule RaffleBot.Discord.Selects.PickWinner do
  @moduledoc """
  Handles the pick_winner_select dropdown response from /pick_winner command.

  Selects a random winner using weighted selection (1 spot = 1 entry)
  and posts a preview with Confirm & Re-Roll buttons.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims

  def handle(%Interaction{data: %{"custom_id" => "pick_winner_select", "values" => [raffle_id]}} = interaction) do
    raffle = Raffles.get_raffle!(raffle_id)

    cond do
      raffle.active ->
        discord_api().create_interaction_response(interaction, 4, %{
          content: "❌ This raffle is still active. Close it first before picking a winner.",
          flags: 64
        })

      raffle.winner_user_id ->
        discord_api().create_interaction_response(interaction, 4, %{
          content: "❌ A winner has already been selected for this raffle: <@#{raffle.winner_user_id}>",
          flags: 64
        })

      true ->
        pick_winner(interaction, raffle)
    end
  end

  defp pick_winner(interaction, raffle) do
    case Raffles.select_random_winner(raffle.id) do
      {:error, :no_paid_claims} ->
        discord_api().create_interaction_response(interaction, 4, %{
          content: "❌ No paid claims found. Cannot pick a winner without paid entries.",
          flags: 64
        })

      {:ok, winning_claim} ->
        # Get all spots for the winner
        user_spots = Raffles.get_user_spots(raffle.id, winning_claim.user_id)
        total_paid = Claims.count_paid_claims(raffle.id)

        # Post winner preview
        post_winner_preview(interaction, raffle, winning_claim, user_spots, total_paid)
    end
  end

  defp post_winner_preview(interaction, raffle, winning_claim, user_spots, total_paid) do
    spot_list = format_spot_list(user_spots)
    entry_count = length(user_spots)

    content = """
    🎲 **Winner Preview** for **#{raffle.title}**

    🏆 <@#{winning_claim.user_id}>
    **Spots:** #{spot_list} (#{entry_count} #{pluralize(entry_count, "entry", "entries")})
    **Winning Entry:** Spot ##{winning_claim.spot_number}
    **Total Entries in Pool:** #{total_paid}

    Use the buttons below to confirm or re-roll.
    """

    components = [
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 3,  # Success (green)
            label: "✅ Confirm & Announce",
            custom_id: "confirm_winner_#{raffle.id}_#{winning_claim.user_id}_#{winning_claim.spot_number}"
          },
          %{
            type: 2,
            style: 2,  # Secondary (gray)
            label: "🔄 Re-Roll",
            custom_id: "reroll_winner_#{raffle.id}_#{winning_claim.user_id}"
          }
        ]
      }
    ]

    discord_api().create_interaction_response(interaction, 4, %{
      content: content,
      components: components,
      flags: 64
    })
  end

  defp format_spot_list(spots) when length(spots) <= 5 do
    Enum.map_join(spots, ", ", &"##{&1}")
  end

  defp format_spot_list(spots) do
    "##{Enum.min(spots)}-##{Enum.max(spots)} (#{length(spots)} spots)"
  end

  defp pluralize(1, singular, _plural), do: singular
  defp pluralize(_, _singular, plural), do: plural
end
