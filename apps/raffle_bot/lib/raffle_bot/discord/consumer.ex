defmodule RaffleBot.Discord.Consumer do
  @moduledoc """
  The Discord event consumer.
  """
  use Nostrum.Consumer

  def start_link, do: start_link(__MODULE__)
  require Logger

  alias Nostrum.Struct.Interaction
  alias RaffleBot.Discord.Commands.SetupRaffle
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

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{type: 2, data: data} = interaction, _ws_state}
      ) do
    task =
      Task.async(fn ->
        case data do
          %{"name" => "setup_raffle"} ->
            SetupRaffle.handle(interaction)

          %{"name" => "mark_paid"} ->
            MarkPaid.handle(interaction)

          %{"name" => "pick_winner"} ->
            PickWinner.handle(interaction)

          %{"name" => "end_raffle"} ->
            EndRaffle.handle(interaction)

          %{"name" => "extend_raffle"} ->
            ExtendRaffle.handle(interaction)

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
end
