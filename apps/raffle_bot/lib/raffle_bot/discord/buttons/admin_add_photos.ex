defmodule RaffleBot.Discord.Buttons.AdminAddPhotos do
  @moduledoc """
  Handles the "Add Photos" button in admin threads.

  When clicked, prompts the admin to reply with photo attachments.
  The bot will then process those attachments and update the raffle.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles

  def handle(%Interaction{data: %{"custom_id" => "admin_add_photos_" <> raffle_id}} = interaction) do
    raffle = Raffles.get_raffle!(raffle_id)

    current_photos =
      if is_list(raffle.photo_urls) and length(raffle.photo_urls) > 0 do
        count = length(raffle.photo_urls)
        "\n\n**Current photos:** #{count} attached"
      else
        ""
      end

    content = """
    📸 **Add Photos to Raffle**

    **Raffle:** #{raffle.title}#{current_photos}

    To add photos, simply **reply to this message** with your photo attachments.

    You can:
    - Attach up to 10 images per message
    - Send multiple replies to add more photos
    - New photos will replace any existing photos

    **Tip:** Drag and drop images or use the attachment button (+) to upload.
    """

    # Send ephemeral prompt
    discord_api().create_interaction_response(
      interaction,
      4,
      %{
        content: content,
        flags: 64  # Ephemeral
      }
    )

    # Also post a public message in the thread that the bot can monitor for replies
    discord_api().create_message(
      interaction.channel_id,
      "",
      [
        content: "📸 **Reply to this message with photos** to add them to **#{raffle.title}**",
        components: [
          %{
            type: 1,
            components: [
              %{
                type: 2,
                style: 2,
                label: "Cancel",
                custom_id: "cancel_photo_upload_#{raffle_id}"
              }
            ]
          }
        ]
      ]
    )
  end
end
