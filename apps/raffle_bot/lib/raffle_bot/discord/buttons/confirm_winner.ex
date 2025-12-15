defmodule RaffleBot.Discord.Buttons.ConfirmWinner do
  @moduledoc """
  Handles the "Confirm & Announce" button for winner selection.

  - Sets winner in database
  - Posts announcement to user raffle thread with shipping button
  - Updates raffle embed with winner
  - Posts confirmation to admin thread
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Discord.Helpers.ButtonRefresher

  def handle(%Interaction{data: %{"custom_id" => "confirm_winner_" <> rest}} = interaction) do
    [raffle_id, user_id, spot_number] = String.split(rest, "_", parts: 3)
    spot_number = String.to_integer(spot_number)

    raffle = Raffles.get_raffle!(raffle_id)
    user_spots = Raffles.get_user_spots(raffle.id, user_id)

    # Set winner in database
    {:ok, updated_raffle} = Raffles.set_winner(raffle, user_id, spot_number)

    # Post announcement to user thread
    post_winner_announcement(updated_raffle, user_id, spot_number, user_spots)

    # Update raffle embed with winner
    update_raffle_embed_with_winner(updated_raffle, user_id)

    # Post confirmation to admin thread
    post_admin_confirmation(updated_raffle, user_id, spot_number, interaction.user.id)

    # Respond to the interaction (update the preview message)
    discord_api().create_interaction_response(interaction, 7, %{
      content: """
      ✅ **Winner Confirmed!**

      <@#{user_id}> has been announced as the winner.
      Announcement posted to raffle thread.
      """,
      components: []  # Remove buttons
    })
  end

  defp post_winner_announcement(raffle, user_id, winning_spot, user_spots) do
    entry_count = length(user_spots)

    content = """
    🎉 **We Have a Winner!**

    Congratulations <@#{user_id}>! 🏆

    You won with spot **##{winning_spot}**!
    (#{entry_count} total #{pluralize(entry_count, "entry", "entries")})

    Please click the button below to submit your shipping details.
    """

    components = [
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 1,  # Primary (blue)
            label: "📦 Submit Shipping Details",
            custom_id: "submit_shipping_#{raffle.id}_#{user_id}"
          }
        ]
      }
    ]

    discord_api().create_message(
      raffle.channel_id,
      "",
      [
        content: content,
        components: components
      ]
    )
  end

  defp update_raffle_embed_with_winner(raffle, user_id) do
    # Refresh buttons to show winner state
    ButtonRefresher.refresh_raffle_buttons(raffle.id)

    # Note: The embed update with winner field would require rebuilding
    # the embed. For now, the announcement serves as the winner indicator.
    # A future enhancement could update the original embed.
  end

  defp post_admin_confirmation(raffle, user_id, winning_spot, admin_id) do
    if raffle.admin_thread_id do
      timestamp = DateTime.utc_now() |> Calendar.strftime("%Y-%m-%d %H:%M UTC")

      content = """
      ✅ **Winner Confirmed & Announced**

      **Winner:** <@#{user_id}>
      **Winning Spot:** ##{winning_spot}
      **Confirmed by:** <@#{admin_id}>
      **Announced at:** #{timestamp}

      ⏳ Awaiting shipping details from winner...
      """

      discord_api().create_message(
        raffle.admin_thread_id,
        "",
        [content: content]
      )
    end
  end

  defp pluralize(1, singular, _plural), do: singular
  defp pluralize(_, _singular, plural), do: plural
end
