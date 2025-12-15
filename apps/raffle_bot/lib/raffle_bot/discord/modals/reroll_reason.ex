defmodule RaffleBot.Discord.Modals.RerollReason do
  @moduledoc """
  Handles the re-roll reason modal submission.

  Records the re-roll in the audit log, posts to admin thread,
  and picks a new winner.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims

  def handle(
        %Interaction{
          data: %{
            "custom_id" => "reroll_reason_modal_" <> rest,
            "components" => components
          }
        } = interaction
      ) do
    [raffle_id, previous_winner_id] = String.split(rest, "_", parts: 2)

    reason = extract_reason(components)
    admin_id = interaction.user.id

    raffle = Raffles.get_raffle!(raffle_id)
    previous_spots = Raffles.get_user_spots(raffle.id, previous_winner_id)

    # Record the re-roll
    {:ok, _reroll} = Raffles.record_reroll(%{
      raffle_id: raffle.id,
      previous_winner_id: previous_winner_id,
      previous_winner_spots: previous_spots,
      rerolled_by_id: to_string(admin_id),
      reason: reason,
      rerolled_at: DateTime.utc_now()
    })

    # Post audit log to admin thread
    post_reroll_audit(raffle, previous_winner_id, previous_spots, admin_id, reason)

    # Pick new winner
    pick_new_winner(interaction, raffle)
  end

  defp extract_reason(components) do
    components
    |> Enum.flat_map(fn %{"components" => inner} -> inner end)
    |> Enum.find(fn %{"custom_id" => id} -> id == "reroll_reason" end)
    |> Map.get("value", "")
  end

  defp post_reroll_audit(raffle, previous_winner_id, previous_spots, admin_id, reason) do
    if raffle.admin_thread_id do
      spot_list = format_spot_list(previous_spots)
      timestamp = DateTime.utc_now() |> Calendar.strftime("%Y-%m-%d %H:%M UTC")

      content = """
      ⚠️ **Re-Roll Record**

      **Previous Winner:** <@#{previous_winner_id}> (#{spot_list})
      **Re-rolled by:** <@#{admin_id}>
      **Reason:** #{reason}
      **Timestamp:** #{timestamp}
      """

      discord_api().create_message(
        raffle.admin_thread_id,
        "",
        [content: content]
      )
    end
  end

  defp pick_new_winner(interaction, raffle) do
    case Raffles.select_random_winner(raffle.id) do
      {:error, :no_paid_claims} ->
        discord_api().create_interaction_response(interaction, 4, %{
          content: "❌ No paid claims found. Cannot pick a winner.",
          flags: 64
        })

      {:ok, winning_claim} ->
        user_spots = Raffles.get_user_spots(raffle.id, winning_claim.user_id)
        total_paid = Claims.count_paid_claims(raffle.id)

        post_new_winner_preview(interaction, raffle, winning_claim, user_spots, total_paid)
    end
  end

  defp post_new_winner_preview(interaction, raffle, winning_claim, user_spots, total_paid) do
    spot_list = format_spot_list(user_spots)
    entry_count = length(user_spots)

    content = """
    🎲 **New Winner Selected** (after re-roll)

    🏆 <@#{winning_claim.user_id}>
    **Spots:** #{spot_list} (#{entry_count} #{pluralize(entry_count, "entry", "entries")})
    **Winning Entry:** Spot ##{winning_claim.spot_number}
    **Total Entries in Pool:** #{total_paid}

    Use the buttons below to confirm or re-roll again.
    """

    components = [
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 3,
            label: "✅ Confirm & Announce",
            custom_id: "confirm_winner_#{raffle.id}_#{winning_claim.user_id}_#{winning_claim.spot_number}"
          },
          %{
            type: 2,
            style: 2,
            label: "🔄 Re-Roll",
            custom_id: "reroll_winner_#{raffle.id}_#{winning_claim.user_id}"
          }
        ]
      }
    ]

    discord_api().create_interaction_response(interaction, 4, %{
      content: content,
      components: components
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
