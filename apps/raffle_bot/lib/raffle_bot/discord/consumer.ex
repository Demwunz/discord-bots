defmodule RaffleBot.Discord.Consumer do
  @moduledoc """
  The Discord event consumer.
  """
  use Nostrum.Consumer

  def start_link, do: start_link(__MODULE__)
  require Logger

  alias Nostrum.Struct.Interaction
  alias RaffleBot.Discord.Commands.SetupRaffle
  alias RaffleBot.Discord.Commands.SetupRaffleAdmin
  alias RaffleBot.Discord.Commands.ConfigureRaffleAdmin
  alias RaffleBot.Discord.Commands.MarkPaid
  alias RaffleBot.Discord.Commands.PickWinner
  alias RaffleBot.Discord.Commands.EndRaffle
  alias RaffleBot.Discord.Commands.ExtendRaffle
  alias RaffleBot.Discord.Modals.RaffleSetup
  alias RaffleBot.Discord.Modals.PaymentConfirm
  alias RaffleBot.Discord.Selects.MarkPaidRaffle
  alias RaffleBot.Discord.Selects.MarkPaidUser
  alias RaffleBot.Discord.Selects.PaymentPlatform
  alias RaffleBot.Discord.Buttons.ClaimSpots
  alias RaffleBot.Discord.Buttons.ClaimSpotButton
  alias RaffleBot.Discord.Buttons.ConfirmClaim
  alias RaffleBot.Discord.Buttons.CancelClaim
  alias RaffleBot.Discord.Buttons.PaymentInfo
  alias RaffleBot.Discord.Buttons.MarkSelfPaid
  alias RaffleBot.Discord.Buttons.AdminConfirmPayment
  alias RaffleBot.Discord.Buttons.AdminRejectPayment
  alias RaffleBot.Discord.Buttons.AdminAddPhotos
  alias RaffleBot.Discord.Buttons.MySpots
  alias RaffleBot.Discord.Buttons.ControlPanelCreateRaffle
  alias RaffleBot.Discord.Buttons.ControlPanelListRaffles
  alias RaffleBot.Discord.Selects.ClaimSpot
  alias RaffleBot.Discord.Selects.ExtendRaffle
  alias RaffleBot.Discord.Authorization
  alias RaffleBot.Discord.ChannelValidator

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{type: 2, data: data} = interaction, _ws_state}
      ) do
    task =
      Task.async(fn ->
        case data do
          %{"name" => "setup_raffle_admin"} ->
            SetupRaffleAdmin.handle(interaction)

          %{"name" => "configure_raffle_admin"} ->
            ConfigureRaffleAdmin.handle(interaction)

          %{"name" => "setup_raffle"} ->
            handle_admin_command(interaction, &SetupRaffle.handle/1)

          %{"name" => "mark_paid"} ->
            handle_admin_command(interaction, &MarkPaid.handle/1)

          %{"name" => "pick_winner"} ->
            handle_admin_command(interaction, &PickWinner.handle/1)

          %{"name" => "end_raffle"} ->
            handle_admin_command(interaction, &EndRaffle.handle/1)

          %{"name" => "extend_raffle"} ->
            handle_admin_command(interaction, &ExtendRaffle.handle/1)

          _ ->
            :noop
        end
      end)

    Task.await(task, 15000)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{type: 5, data: data} = interaction, _ws_state}
      ) do
    task =
      Task.async(fn ->
        case data do
          %{"custom_id" => "raffle_setup_modal"} ->
            RaffleSetup.handle(interaction)

          %{"custom_id" => "payment_confirm_modal_" <> _rest} ->
            PaymentConfirm.handle(interaction)

          _ ->
            :noop
        end
      end)

    Task.await(task, 15000)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{type: 3, data: data} = interaction, _ws_state}
      ) do
    task =
      Task.async(fn ->
        case data do
          # Control Panel button handlers
          %{"custom_id" => "control_panel_create_raffle"} ->
            handle_admin_command(interaction, &ControlPanelCreateRaffle.handle/1)

          %{"custom_id" => "control_panel_list_raffles"} ->
            handle_admin_command(interaction, &ControlPanelListRaffles.handle/1)

          # New per-spot button handlers
          %{"custom_id" => "claim_spot_" <> _rest} ->
            ClaimSpotButton.handle(interaction)

          %{"custom_id" => "confirm_claim_" <> _rest} ->
            ConfirmClaim.handle(interaction)

          %{"custom_id" => "cancel_claim"} ->
            CancelClaim.handle(interaction)

          # Payment flow buttons
          %{"custom_id" => "payment_info_" <> _rest} ->
            PaymentInfo.handle(interaction)

          %{"custom_id" => "mark_self_paid_" <> _rest} ->
            MarkSelfPaid.handle(interaction)

          # Admin payment confirmation buttons
          %{"custom_id" => "admin_confirm_payment_" <> _rest} ->
            handle_admin_command(interaction, &AdminConfirmPayment.handle/1)

          %{"custom_id" => "admin_reject_payment_" <> _rest} ->
            handle_admin_command(interaction, &AdminRejectPayment.handle/1)

          %{"custom_id" => "admin_add_photos_" <> _rest} ->
            handle_admin_command(interaction, &AdminAddPhotos.handle/1)

          %{"custom_id" => "cancel_photo_upload_" <> _rest} ->
            # Just delete the prompt message
            :noop

          # User utility buttons
          %{"custom_id" => "my_spots_" <> _rest} ->
            MySpots.handle(interaction)

          # Existing handlers (backwards compatibility)
          %{"custom_id" => "claim_spots"} ->
            ClaimSpots.handle(interaction)

          %{"custom_id" => "claim_spot_select_" <> _raffle_id} ->
            ClaimSpot.handle(interaction)

          %{"custom_id" => "mark_paid_raffle_select"} ->
            MarkPaidRaffle.handle(interaction)

          %{"custom_id" => "mark_paid_user_select"} ->
            MarkPaidUser.handle(interaction)

          %{"custom_id" => "extend_raffle_select"} ->
            ExtendRaffle.handle(interaction)

          # Payment platform selection
          %{"custom_id" => "payment_platform_select_" <> _rest} ->
            PaymentPlatform.handle(interaction)

          _ ->
            :noop
        end
      end)

    Task.await(task, 15000)
  end

  # Handle message create events for photo uploads
  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    # Check if this is a reply with attachments in an admin thread
    handle_photo_upload(message)
  end

  def handle_event(_event), do: :ok

  # Process potential photo uploads in admin threads
  defp handle_photo_upload(%{
         attachments: attachments,
         channel_id: channel_id,
         referenced_message: %{content: content}
       })
       when is_list(attachments) and length(attachments) > 0 do
    # Check if the referenced message is our photo upload prompt
    if String.contains?(content, "Reply to this message with photos") do
      # Extract raffle title from the message
      case Regex.run(~r/to add them to \*\*(.+)\*\*/, content) do
        [_, raffle_title] ->
          process_photo_attachments(channel_id, raffle_title, attachments)

        _ ->
          :noop
      end
    end
  end

  defp handle_photo_upload(_), do: :noop

  defp process_photo_attachments(channel_id, raffle_title, attachments) do
    alias RaffleBot.Raffles

    # Find raffle by admin thread ID (channel_id is the thread ID)
    case Raffles.get_raffle_by_admin_thread(to_string(channel_id)) do
      nil ->
        :noop

      raffle ->
        # Extract image URLs from attachments
        photo_urls =
          attachments
          |> Enum.filter(fn att ->
            content_type = Map.get(att, :content_type, "")
            String.starts_with?(content_type, "image/")
          end)
          |> Enum.map(& &1.url)

        if length(photo_urls) > 0 do
          # Update raffle with new photos
          Raffles.update_raffle(raffle, %{photo_urls: photo_urls})

          # Update the raffle embed in the user thread
          update_raffle_embed_with_photos(raffle, photo_urls)

          # Send confirmation in admin thread
          api_module = Application.get_env(:raffle_bot, :discord_api) || Nostrum.Api
          api_module.create_message(
            channel_id,
            "",
            [content: "✅ **#{length(photo_urls)} photo(s) added** to #{raffle_title}!"]
          )
        end
    end
  end

  defp update_raffle_embed_with_photos(raffle, photo_urls) do
    alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed
    alias RaffleBot.Claims

    api_module = Application.get_env(:raffle_bot, :discord_api) || Nostrum.Api
    claims = Claims.get_claims_by_raffle(raffle.id)

    # Rebuild the embed with photos
    embed = RaffleEmbed.build(raffle, claims)
    embed_with_photos = add_photos_to_embed(embed, photo_urls)

    api_module.edit_message(
      raffle.channel_id,
      raffle.message_id,
      %{embeds: [embed_with_photos]}
    )
  end

  defp add_photos_to_embed(embed, [first_url | _rest] = _photo_urls) do
    # Discord embeds support one main image
    # Set the first photo as the embed image
    Map.put(embed, :image, %{url: first_url})
  end

  defp add_photos_to_embed(embed, _), do: embed

  # Private helper for handling admin commands with authorization and channel validation
  defp handle_admin_command(interaction, command_handler) do
    case Authorization.authorize_admin(interaction) do
      {:ok, _config} ->
        # User is authorized, check channel and execute command
        case ChannelValidator.validate_channel(interaction, :admin) do
          {:ok, nil} ->
            # Correct channel, execute command
            command_handler.(interaction)

          {:ok, warning} ->
            # Wrong channel, execute command but prepend warning
            # Note: This requires command handlers to support warning injection
            # For now, just execute the command normally
            Logger.warning("Admin command used in non-admin channel: #{warning}")
            command_handler.(interaction)
        end

      {:error, reason} ->
        # User is not authorized, send unauthorized response
        Authorization.unauthorized_response(reason)
        |> send_unauthorized_response(interaction)
    end
  end

  defp send_unauthorized_response(response, interaction) do
    case Application.get_env(:raffle_bot, :discord_api) do
      nil ->
        Nostrum.Api.create_interaction_response(interaction, response.type, response.data)

      api_module ->
        api_module.create_interaction_response(interaction, response.type, response.data)
    end
  end
end
