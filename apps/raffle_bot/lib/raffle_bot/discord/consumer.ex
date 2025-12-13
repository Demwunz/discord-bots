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
  alias RaffleBot.Discord.Selects.MarkPaidRaffle
  alias RaffleBot.Discord.Selects.MarkPaidUser
  alias RaffleBot.Discord.Buttons.ClaimSpots
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

          _ ->
            :noop
        end
      end)

    Task.await(task, 15000)
  end

  def handle_event(_event), do: :ok

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
