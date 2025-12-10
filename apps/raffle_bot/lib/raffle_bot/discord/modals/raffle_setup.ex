defmodule RaffleBot.Discord.Modals.RaffleSetup do
  @moduledoc """
  Handles the raffle setup modal submission.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed

  def handle(%Interaction{data: %{"components" => components}, channel_id: channel_id} = interaction) do
    attrs =
      Enum.reduce(components, %{}, fn %{"components" => [%{"custom_id" => id, "value" => value}]}, acc ->
        Map.put(acc, id, value)
      end)

    case Raffles.create_raffle(Map.put(attrs, :channel_id, channel_id)) do
      {:ok, raffle} ->
        discord_api().create_interaction_response(
          interaction,
          4,
          %{
            embeds: [RaffleEmbed.build(raffle, [])],
            components: RaffleEmbed.components(raffle, [])
          }
        )

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} ->
            msg
          end)
          |> Enum.map(fn {field, msg} ->
            "`#{field}`: #{msg}"
          end)
          |> Enum.join("\n")

        discord_api().create_interaction_response(
          interaction,
          4,
          %{
            content: "Error creating raffle:\n#{errors}",
            flags: 64
          }
        )
    end
  end
end
