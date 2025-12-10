defmodule RaffleBot.Discord.Commands.MySpots do
  @moduledoc """
  User command to check all their claimed spots.
  """

  alias Nostrum.Api
  alias Nostrum.Struct.{Interaction, Embed}
  alias RaffleBot.{Claims, Raffles}

  def handle(%Interaction{member: %{user: %{id: user_id}}} = interaction) do
    user_claims = Claims.get_claims_by_user(user_id)
    
    if Enum.empty?(user_claims) do
      Api.create_interaction_response(interaction, %{
        type: 4,
        data: %{
          content: "You haven't claimed any raffle spots yet! 🎟️",
          flags: 64
        }
      })
    else
      embed = build_user_spots_embed(user_id, user_claims)
      
      Api.create_interaction_response(interaction, %{
        type: 4,
        data: %{
          embeds: [embed],
          flags: 64
        }
      })
    end
  end

  defp build_user_spots_embed(user_id, claims) do
    total_spots = length(claims)
    paid_spots = Enum.count(claims, & &1.is_paid)
    
    %Embed{
      title: "🎟️ Your Raffle Spots",
      description: "Total: #{total_spots} spots (#{paid_spots} paid)",
      color: 0x5865F2,
      fields: build_raffle_fields(claims),
      timestamp: DateTime.to_iso8601(DateTime.utc_now())
    }
  end

  defp build_raffle_fields(claims) do
    claims
    |> Enum.group_by(& &1.raffle_id)
    |> Enum.map(fn {raffle_id, raffle_claims} ->
      raffle = Raffles.get_raffle!(raffle_id)
      spots = raffle_claims |> Enum.map(& &1.spot_number) |> Enum.sort() |> Enum.join(", ")
      paid = Enum.count(raffle_claims, & &1.is_paid)
      
      %{
        name: raffle.title,
        value: "Spots: #{spots}\nPaid: #{paid}/#{length(raffle_claims)}",
        inline: false
      }
    end)
  end
end
