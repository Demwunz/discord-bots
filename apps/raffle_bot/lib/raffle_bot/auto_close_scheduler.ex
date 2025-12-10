defmodule RaffleBot.AutoCloseScheduler do
  @moduledoc """
  GenServer that automatically closes raffles based on their duration.
  """
  use GenServer
  require Logger

  alias RaffleBot.{Raffles, Claims}
  alias RaffleBot.Discord.Embeds.RaffleEmbed
  alias Nostrum.Api

  @check_interval :timer.minutes(1)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_check()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_raffles, state) do
    check_and_close_raffles()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_raffles, @check_interval)
  end

  defp check_and_close_raffles do
    now = DateTime.utc_now()
    
    Raffles.list_active_raffles()
    |> Enum.filter(fn raffle ->
      raffle.auto_close_at && DateTime.compare(raffle.auto_close_at, now) == :lt
    end)
    |> Enum.each(&close_raffle/1)
  end

  defp close_raffle(raffle) do
    Logger.info("Auto-closing raffle: #{raffle.title}")
    {:ok, closed_raffle} = Raffles.close_raffle(raffle)
    
    claims = Claims.get_claims_by_raffle(raffle.id)
    embed = RaffleEmbed.build(closed_raffle, claims)
    
    try do
      Api.edit_message(raffle.channel_id, raffle.message_id, %{
        embeds: [embed],
        components: []
      })
      
      admin_channel_id = Application.get_env(:raffle_bot, :admin_channel_id)
      if admin_channel_id do
        Api.create_message(admin_channel_id, %{
          content: "⏰ Raffle **#{raffle.title}** auto-closed after #{raffle.duration_days} days."
        })
      end
    rescue
      e -> Logger.error("Failed to update Discord: #{inspect(e)}")
    end
  end
end
