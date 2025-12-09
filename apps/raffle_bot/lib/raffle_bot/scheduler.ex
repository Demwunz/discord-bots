defmodule RaffleBot.Scheduler do
  @moduledoc """
  A GenServer that sends a daily report of new claims.
  """
  use GenServer
  require Logger
  alias RaffleBot.Claims

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:report, state) do
    Logger.info("Fetching new claims...")
    claims = Claims.get_claims_from_last_24_hours()
    Logger.info("Found #{length(claims)} new claims. Reporting...")
    # TODO: Send report to Discord instead of logging
    Logger.info(inspect(claims))
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    # 24 hours in milliseconds
    Process.send_after(self(), :report, 24 * 60 * 60 * 1000)
  end
end
