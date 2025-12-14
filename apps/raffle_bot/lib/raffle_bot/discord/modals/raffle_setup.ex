defmodule RaffleBot.Discord.Modals.RaffleSetup do
  @moduledoc """
  Handles the raffle setup modal submission.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles
  alias RaffleBot.GuildConfig
  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed
  alias RaffleBot.Discord.Components.AdminThread

  def handle(
        %Interaction{
          data: %{"components" => components},
          channel_id: channel_id,
          guild_id: guild_id
        } = interaction
      ) do
    attrs =
      Enum.reduce(components, %{}, fn %{"components" => [%{"custom_id" => id, "value" => value}]},
                                      acc ->
        Map.put(acc, id, value)
      end)

    # Get guild configuration for channel IDs
    config = GuildConfig.get_guild_config_by_guild_id(to_string(guild_id))

    case Raffles.create_raffle(Map.put(attrs, :channel_id, channel_id)) do
      {:ok, raffle} ->
        # Build embed and first page of spot buttons
        embed = RaffleEmbed.build(raffle, [])
        buttons_page_1 = RaffleEmbed.build_spot_buttons(raffle, [], 1)

        # Create forum thread in raffles-v2 (user channel)
        case discord_api().start_forum_thread(
               config.user_channel_id,
               raffle.title,
               %{
                 embeds: [embed],
                 components: buttons_page_1
               }
             ) do
          {:ok, %{"id" => thread_id, "message" => %{"id" => first_message_id}}} ->
            # Safely extracted thread_id and first_message_id
            message_ids = [first_message_id]

            # If > 25 spots, create additional messages as thread replies
            additional_ids =
              if raffle.total_spots > 25 do
                num_pages = ceil(raffle.total_spots / 25)

                for page <- 2..num_pages do
                  buttons = RaffleEmbed.build_spot_buttons(raffle, [], page)
                  start_spot = (page - 1) * 25 + 1
                  end_spot = min(page * 25, raffle.total_spots)

                  {:ok, msg} =
                    discord_api().create_message(
                      thread_id,
                      "",
                      [
                        content: "**Spots #{start_spot} - #{end_spot}**",
                        components: buttons
                      ]
                    )

                  msg.id
                end
              else
                []
              end

            all_message_ids = message_ids ++ additional_ids

            # Update raffle with thread and message IDs
            {:ok, updated_raffle} =
              Raffles.update_raffle(raffle, %{
                message_id: hd(all_message_ids),
                channel_id: thread_id,
                spot_button_message_ids: tl(all_message_ids)
              })

            # Create admin forum thread in admin channel
            admin_message = AdminThread.build_admin_message(updated_raffle, [])

            case discord_api().start_forum_thread(
                   config.admin_channel_id,
                   "🎯 #{updated_raffle.title}",
                   admin_message
                 ) do
              {:ok, %{"id" => admin_thread_id, "message" => %{"id" => admin_message_id}}} ->
                # Update raffle with admin thread info
                Raffles.update_raffle(updated_raffle, %{
                  admin_thread_id: admin_thread_id,
                  admin_thread_message_id: admin_message_id
                })

                # Send success response (ephemeral)
                discord_api().create_interaction_response(
                  interaction,
                  4,
                  %{
                    content:
                      "✅ Raffle created! View it in <##{config.user_channel_id}>\n📊 Admin thread: <##{admin_thread_id}>",
                    flags: 64
                  }
                )

              {:error, admin_reason} ->
                # Admin thread creation failed, but user thread was successful
                # Log error and continue
                require Logger

                Logger.warning(
                  "Failed to create admin thread for raffle #{updated_raffle.id}: #{inspect(admin_reason)}"
                )

                # Send success response but note admin thread issue
                discord_api().create_interaction_response(
                  interaction,
                  4,
                  %{
                    content:
                      "✅ Raffle created! View it in <##{config.user_channel_id}>\n⚠️ Admin thread creation failed - check logs",
                    flags: 64
                  }
                )
            end

          {:ok, unexpected} ->
            # Handle unexpected successful response structure
            require Logger
            Logger.error("Unexpected forum thread response: #{inspect(unexpected)}")

            discord_api().create_interaction_response(
              interaction,
              4,
              %{
                content: "Error creating raffle: Received an unexpected response from Discord.",
                flags: 64
              }
            )

          {:error, reason} ->
            # Forum thread creation failed
            discord_api().create_interaction_response(
              interaction,
              4,
              %{
                content: "Error creating raffle thread: #{inspect(reason)}",
                flags: 64
              }
            )
        end

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
