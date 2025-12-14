defmodule RaffleBot.Discord.Buttons.MySpots do
  @moduledoc """
  Handles the "My Spots" button on raffle messages.
  Shows the user their claimed spots for this raffle with payment status.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Claims

  def handle(%Interaction{data: %{"custom_id" => "my_spots_" <> raffle_id}} = interaction) do
    user_id = interaction.user.id
    raffle = Raffles.get_raffle!(raffle_id)
    user_claims = Claims.get_user_claims_for_raffle(user_id, raffle_id)

    content =
      if Enum.empty?(user_claims) do
        "🎟️ **My Spots**\n\nYou haven't claimed any spots in **#{raffle.title}** yet.\n\nClick an available spot button to claim one!"
      else
        build_spots_summary(raffle, user_claims)
      end

    # Show ephemeral response with their spots
    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: content,
        flags: 64  # Ephemeral
      }
    )
  end

  defp build_spots_summary(raffle, claims) do
    spots = Enum.map(claims, & &1.spot_number) |> Enum.sort()
    spot_list = Enum.join(spots, ", ")
    total_amount = length(claims) * raffle.price

    paid_count = Enum.count(claims, & &1.is_paid)
    pending_count = Enum.count(claims, & &1.user_marked_paid && !&1.is_paid)
    unpaid_count = length(claims) - paid_count - pending_count

    status_lines = []

    status_lines =
      if paid_count > 0 do
        status_lines ++ ["✅ **#{paid_count}** spot(s) confirmed paid"]
      else
        status_lines
      end

    status_lines =
      if pending_count > 0 do
        status_lines ++ ["💵 **#{pending_count}** spot(s) pending admin confirmation"]
      else
        status_lines
      end

    status_lines =
      if unpaid_count > 0 do
        status_lines ++ ["⏳ **#{unpaid_count}** spot(s) awaiting payment"]
      else
        status_lines
      end

    status_text = Enum.join(status_lines, "\n")

    """
    🎟️ **My Spots - #{raffle.title}**

    **Your Spots:** #{spot_list}
    **Total:** $#{total_amount}

    **Status:**
    #{status_text}
    """
  end
end
