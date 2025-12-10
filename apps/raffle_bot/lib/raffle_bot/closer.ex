defmodule RaffleBot.Closer do
  @moduledoc """
  GenServer that handles the closing of raffles.
  """
  use GenServer
  require Logger

  alias RaffleBot.Raffles
  alias RaffleBot.Claims
  alias RaffleBot.Discord.Embeds.Raffle, as: RaffleEmbed
  use RaffleBot.Discord.ApiConsumer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule_close(raffle) do
    milliseconds = DateTime.diff(raffle.auto_close_at, DateTime.utc_now(), :millisecond)
    if milliseconds > 0 do
      Process.send_after(self(), {:close, raffle.id}, milliseconds)
    end
  end

  @impl true
  def init(_opts) do
    Raffles.list_active_raffles()
    |> Enum.each(&schedule_close/1)
    {:ok, %{}}
  end

  @impl true
  def handle_info({:close, raffle_id}, state) do
    case Raffles.get_raffle(raffle_id) do
      nil ->
        :ok # Raffle was deleted
      raffle ->
        # Check if the raffle is still active and if the close time is in the past.
        # This is to prevent closing a raffle that was extended.
        if raffle.active && DateTime.compare(raffle.auto_close_at, DateTime.utc_now()) == :lt do
          close_raffle(raffle)
        end
    end
    {:noreply, state}
  end

  defp close_raffle(raffle) do
    Logger.info("Auto-closing raffle: #{raffle.title}")
    {:ok, closed_raffle} = Raffles.close_raffle(raffle)
    
    claims = Claims.get_claims_by_raffle(raffle.id)
    embed = RaffleEmbed.build(closed_raffle, claims)
    
    try do
      discord_api().edit_message(raffle.channel_id, raffle.message_id, %{
        embeds: [embed],
        components: []
      })
      
      admin_channel_id = Application.get_env(:raffle_bot, :admin_channel_id)
      if admin_channel_id do
        discord_api().create_message(admin_channel_id, %{
          content: "⏰ Raffle **#{raffle.title}** auto-closed."
        })
      end
    rescue
      e -> Logger.error("Failed to update Discord: #{inspect(e)}")
    end
  end
end
