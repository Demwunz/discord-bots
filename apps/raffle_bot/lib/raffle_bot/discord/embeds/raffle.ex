defmodule RaffleBot.Discord.Embeds.Raffle do
  @moduledoc """
  Handles the creation of the raffle embed.
  """

  alias Nostrum.Struct.Embed
  alias RaffleBot.Raffles.Raffle

  def build(%Raffle{} = raffle, claims) do
    spots_claimed = length(claims)
    spots_remaining = raffle.total_spots - spots_claimed
    participants = Enum.map(claims, &" <@#{&1.user_id}>") |> Enum.join(", ")

    %Embed{
      title: "Raffle Time!",
      description: raffle.description,
      color: 0x57F287,
      fields: [
        %{name: "Title", value: raffle.title, inline: true},
        %{name: "Price", value: to_string(raffle.price), inline: true},
        %{name: "Total Spots", value: to_string(raffle.total_spots), inline: true},
        %{name: "Spots Claimed", value: to_string(spots_claimed), inline: true},
        %{name: "Spots Remaining", value: to_string(spots_remaining), inline: true},
        %{name: "Participants", value: participants}
      ]
    }
  end

  def components(%Raffle{} = raffle, claims) do
    spots_claimed = length(claims)

    if spots_claimed >= raffle.total_spots do
      []
    else
      [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              style: 1,
              label: "🎟️ Claim Spots",
              custom_id: "claim_spots_#{raffle.id}"
            }
          ]
        }
      ]
    end
  end

  @doc """
  Builds spot button components for a given raffle page.
  Discord limits buttons to 25 per message (5 rows × 5 buttons).

  ## Parameters
    - raffle: The Raffle struct
    - claims: List of claims for this raffle
    - page: Page number (1-indexed) for pagination

  ## Returns
    List of action row components (max 5 rows with 5 buttons each)
  """
  def build_spot_buttons(%Raffle{} = raffle, claims, page \\ 1) do
    # Calculate spot range for this page (25 spots per page)
    start_spot = (page - 1) * 25 + 1
    end_spot = min(page * 25, raffle.total_spots)

    # Build button grid (5 rows × 5 buttons)
    start_spot..end_spot
    |> Enum.chunk_every(5)  # 5 buttons per row
    |> Enum.map(fn spot_numbers ->
      %{
        type: 1,  # Action row
        components: Enum.map(spot_numbers, &build_spot_button(raffle, claims, &1))
      }
    end)
  end

  @doc """
  Builds a single spot button based on its claim status.

  ## Button States
    - Available: Blue primary button with ➡️ and spot number
    - Claimed (unpaid): Gray secondary button with @username, disabled
    - User marked as paid (pending admin confirmation): Gray with ✅ @username
    - Admin confirmed paid: Green success button with ✅ @username, disabled
  """
  defp build_spot_button(raffle, claims, spot_number) do
    case find_claim(claims, spot_number) do
      nil ->
        # Available spot
        %{
          type: 2,  # Button
          style: 1,  # Primary (blue)
          label: "➡️ #{spot_number}",
          custom_id: "claim_spot_#{raffle.id}_#{spot_number}"
        }

      %{is_paid: true, user_id: user_id} ->
        # Admin confirmed paid spot
        %{
          type: 2,
          style: 3,  # Success (green)
          label: truncate_username(format_username(user_id), 72) <> " ✅",
          custom_id: "confirmed_paid_#{raffle.id}_#{spot_number}",
          disabled: true
        }

      %{user_marked_paid: true, user_id: user_id} ->
        # User marked as paid (pending admin confirmation)
        %{
          type: 2,
          style: 2,  # Secondary (gray) - will be yellow when Discord supports it
          label: "✅ " <> truncate_username(format_username(user_id), 75),
          custom_id: "user_paid_#{raffle.id}_#{spot_number}",
          disabled: true
        }

      %{user_id: user_id} ->
        # Claimed but unpaid
        %{
          type: 2,
          style: 2,  # Secondary (gray)
          label: truncate_username(format_username(user_id), 80),
          custom_id: "claimed_#{raffle.id}_#{spot_number}",
          disabled: true
        }
    end
  end

  @doc """
  Finds a claim for a specific spot number.
  """
  defp find_claim(claims, spot_number) do
    Enum.find(claims, fn claim -> claim.spot_number == spot_number end)
  end

  @doc """
  Formats a user ID as a Discord mention.
  Falls back to "@#{user_id}" for display.
  """
  defp format_username(user_id) do
    "@#{user_id}"
  end

  @doc """
  Truncates a username to fit within Discord's button label limit.
  Discord button labels have a max length of 80 characters.
  """
  defp truncate_username(username, max_length) do
    if String.length(username) > max_length do
      String.slice(username, 0, max_length - 3) <> "..."
    else
      username
    end
  end
end
