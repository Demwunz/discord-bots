defmodule RaffleBot.Discord.Components.AdminThread do
  @moduledoc """
  Builds components for admin forum threads.

  Each raffle gets its own admin forum thread in the configured admin channel.
  This module provides functions to build the embeds and buttons for these threads.
  """

  alias RaffleBot.Raffles.Raffle
  alias RaffleBot.Claims.Claim

  @doc """
  Builds the admin embed for a raffle.

  Displays raffle information and statistics for admin monitoring.

  ## Parameters

    * `raffle` - The Raffle struct
    * `claims` - List of Claim structs for this raffle

  ## Returns

    A Discord embed map
  """
  def build_admin_embed(%Raffle{} = raffle, claims \\ []) do
    claimed_count = length(claims)
    paid_count = Enum.count(claims, & &1.is_paid)
    pending_count = claimed_count - paid_count

    status_emoji = if raffle.active, do: "🟢", else: "🔴"
    status_text = if raffle.active, do: "Active", else: "Closed"

    %{
      title: "🎯 Raffle: #{raffle.title}",
      color: if(raffle.active, do: 0x57F287, else: 0xED4245),
      fields: [
        %{
          name: "Status",
          value: "#{status_emoji} #{status_text}",
          inline: true
        },
        %{
          name: "Price per Spot",
          value: "$#{raffle.price}",
          inline: true
        },
        %{
          name: "Total Spots",
          value: "#{raffle.total_spots}",
          inline: true
        },
        %{
          name: "Claimed",
          value: "#{claimed_count}/#{raffle.total_spots}",
          inline: true
        },
        %{
          name: "Paid",
          value: "✅ #{paid_count}",
          inline: true
        },
        %{
          name: "Pending Payment",
          value: "⏳ #{pending_count}",
          inline: true
        }
      ],
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    |> maybe_add_payment_details(raffle)
  end

  defp maybe_add_payment_details(embed, %Raffle{payment_details: details})
       when is_binary(details) and details != "" do
    Map.update!(embed, :fields, fn fields ->
      fields ++
        [
          %{
            name: "Payment Details",
            value: details,
            inline: false
          }
        ]
    end)
  end

  defp maybe_add_payment_details(embed, _raffle), do: embed

  @doc """
  Builds the admin action buttons for a raffle.

  Provides buttons for common admin actions like marking paid, extending duration,
  closing the raffle, and picking a winner.

  ## Parameters

    * `raffle` - The Raffle struct

  ## Returns

    A list of action row components
  """
  def build_admin_buttons(%Raffle{} = raffle) do
    components = []

    # Management buttons (if active)
    components =
      if raffle.active do
        components ++
          [
            %{
              type: 1,
              components: [
                %{
                  type: 2,
                  style: 1,
                  label: "💰 Mark Paid",
                  custom_id: "admin_panel_mark_paid_#{raffle.id}"
                },
                %{
                  type: 2,
                  style: 1,
                  label: "⏰ Extend Duration",
                  custom_id: "admin_panel_extend_#{raffle.id}"
                }
              ]
            }
          ]
      else
        components
      end

    # Close/Pick Winner button
    components =
      components ++
        [
          %{
            type: 1,
            components: [
              if raffle.active do
                %{
                  type: 2,
                  style: 4,
                  label: "🔒 Close Raffle",
                  custom_id: "admin_panel_close_#{raffle.id}"
                }
              else
                %{
                  type: 2,
                  style: 3,
                  label: "🏆 Pick Winner",
                  custom_id: "admin_panel_pick_winner_#{raffle.id}"
                }
              end
            ]
          }
        ]

    components
  end

  @doc """
  Builds a complete admin thread message with embed and buttons.

  ## Parameters

    * `raffle` - The Raffle struct
    * `claims` - List of Claim structs for this raffle (optional)

  ## Returns

    A map with :embeds and :components keys
  """
  def build_admin_message(raffle, claims \\ []) do
    %{
      embeds: [build_admin_embed(raffle, claims)],
      components: build_admin_buttons(raffle)
    }
  end
end
