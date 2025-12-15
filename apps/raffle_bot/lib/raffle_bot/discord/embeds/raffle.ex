defmodule RaffleBot.Discord.Embeds.Raffle do
  @moduledoc """
  Handles the creation of the raffle embed.
  """

  alias Nostrum.Struct.Embed
  alias RaffleBot.Raffles.Raffle

  def build(%Raffle{} = raffle, _claims) do
    description = build_description(raffle)

    embed = %Embed{
      title: "🎟️ Raffle Time! — #{raffle.title}",
      description: description,
      color: 0x57F287
    }

    # Add image if photos exist
    add_image_to_embed(embed, raffle)
  end

  defp build_description(raffle) do
    sections = [
      # Description
      raffle.description,
      "",
      # Grading link (if provided)
      build_grading_link(raffle.grading_link),
      # Price and spots info
      "💵 Spots are **$#{raffle.price}** each — grab as many as you want!",
      "🎯 **#{raffle.total_spots}** total spots — pick your spot by clicking the buttons below!",
      "",
      "Raffles will run as soon as all spots are filled.",
      "If we don't fill it up within **#{raffle.duration_days || 7}** days, this one will close and we'll kick off a fresh raffle.",
      "",
      # Shipping section
      "📦 **Shipping Info:**",
      "🇺🇸 US: #{raffle.us_shipping || "Free USPS Ground Advantage"}",
      build_international_shipping(raffle.international_shipping),
      "",
      # Payment note (details shown only when paying)
      "💳 Payment collected once all spots are full — click **My Spots** to pay."
    ]

    sections
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp build_grading_link(nil), do: nil
  defp build_grading_link(""), do: nil
  defp build_grading_link(link), do: "🔗 **Grading:** [View Certificate](#{link})\n"

  defp build_international_shipping(nil), do: "🌍 No international shipping for this raffle."
  defp build_international_shipping(""), do: "🌍 No international shipping for this raffle."
  defp build_international_shipping(details), do: "🌍 International: #{details}"

  defp build_payment_details(nil), do: "Venmo, Zelle or PayPal is good to go."
  defp build_payment_details(""), do: "Venmo, Zelle or PayPal is good to go."
  defp build_payment_details(details), do: details

  defp add_image_to_embed(embed, %Raffle{photo_urls: [first_url | _]}) do
    Map.put(embed, :image, %{url: first_url})
  end

  defp add_image_to_embed(embed, %Raffle{photo_url: url}) when is_binary(url) and url != "" do
    Map.put(embed, :image, %{url: url})
  end

  defp add_image_to_embed(embed, _raffle), do: embed

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
  We reserve one row for utility buttons, so max 20 spot buttons per page.

  ## Parameters
    - raffle: The Raffle struct
    - claims: List of claims for this raffle
    - page: Page number (1-indexed) for pagination

  ## Returns
    List of action row components (max 4 rows of spots + 1 utility row)
  """
  def build_spot_buttons(%Raffle{} = raffle, claims, page \\ 1) do
    # Calculate spot range for this page (20 spots per page to leave room for utility row)
    spots_per_page = 20
    start_spot = (page - 1) * spots_per_page + 1
    end_spot = min(page * spots_per_page, raffle.total_spots)

    # Check if raffle is sold out (determines if we show payment pending icons)
    is_sold_out = length(claims) >= raffle.total_spots

    # Build button grid (4 rows × 5 buttons for spots)
    spot_rows =
      start_spot..end_spot
      |> Enum.chunk_every(5)  # 5 buttons per row
      |> Enum.map(fn spot_numbers ->
        %{
          type: 1,  # Action row
          components: Enum.map(spot_numbers, &build_spot_button(raffle, claims, &1, is_sold_out))
        }
      end)

    # Add utility row with "My Spots" button (only on first page)
    if page == 1 do
      spot_rows ++ [build_utility_row(raffle)]
    else
      spot_rows
    end
  end

  @doc """
  Builds the utility button row with "My Spots" button.
  """
  def build_utility_row(%Raffle{} = raffle) do
    %{
      type: 1,  # Action row
      components: [
        %{
          type: 2,
          style: 2,  # Secondary (gray)
          label: "🎟️ My Spots",
          custom_id: "my_spots_#{raffle.id}"
        }
      ]
    }
  end

  # Builds a single spot button based on its claim status.
  # Button States (5 states, always show spot number first):
  #   1. Available: Blue [#. Claim]
  #   2. Claimed (raffle not full): Gray [#. @user] - no emoji
  #   3. Payment pending (raffle full): Gray [#. @user 💵]
  #   4. User marked paid: Gray [#. @user 💸]
  #   5. Admin confirmed: Green [#. @user ✅]
  defp build_spot_button(raffle, claims, spot_number, is_sold_out) do
    case find_claim(claims, spot_number) do
      nil ->
        # State 1: Available spot - numbered claim button
        %{
          type: 2,  # Button
          style: 1,  # Primary (blue)
          label: "#{spot_number}. Claim",
          custom_id: "claim_spot_#{raffle.id}_#{spot_number}"
        }

      %{is_paid: true, user_id: user_id} ->
        # State 5: Admin confirmed paid
        %{
          type: 2,
          style: 3,  # Success (green)
          label: "#{spot_number}. " <> truncate_username(format_username(user_id), 70) <> " ✅",
          custom_id: "confirmed_paid_#{raffle.id}_#{spot_number}",
          disabled: true
        }

      %{user_marked_paid: true, user_id: user_id} ->
        # State 4: User marked as paid (pending admin confirmation)
        %{
          type: 2,
          style: 2,  # Secondary (gray)
          label: "#{spot_number}. " <> truncate_username(format_username(user_id), 70) <> " 💸",
          custom_id: "user_paid_#{raffle.id}_#{spot_number}",
          disabled: true
        }

      %{user_id: user_id} ->
        # State 2 or 3: Claimed but unpaid
        if is_sold_out do
          # State 3: Payment pending (raffle is full)
          %{
            type: 2,
            style: 2,  # Secondary (gray)
            label: "#{spot_number}. " <> truncate_username(format_username(user_id), 70) <> " 💵",
            custom_id: "claimed_#{raffle.id}_#{spot_number}",
            disabled: true
          }
        else
          # State 2: Just claimed (raffle still has open spots)
          %{
            type: 2,
            style: 2,  # Secondary (gray)
            label: "#{spot_number}. " <> truncate_username(format_username(user_id), 74),
            custom_id: "claimed_#{raffle.id}_#{spot_number}",
            disabled: true
          }
        end
    end
  end

  # Finds a claim for a specific spot number.
  defp find_claim(claims, spot_number) do
    Enum.find(claims, fn claim -> claim.spot_number == spot_number end)
  end

  # Formats a user ID as a Discord mention.
  # Falls back to @user_id format for display.
  defp format_username(user_id) do
    "@#{user_id}"
  end

  # Truncates a username to fit within Discord's button label limit.
  # Discord button labels have a max length of 80 characters.
  defp truncate_username(username, max_length) do
    if String.length(username) > max_length do
      String.slice(username, 0, max_length - 3) <> "..."
    else
      username
    end
  end
end
