defmodule RaffleBot.Scheduler do
  @moduledoc """
  A GenServer that sends a daily report of new claims.
  """
  use GenServer

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
    # TODO: Fetch new claims and send the report
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    # 24 hours in milliseconds
    Process.send_after(self(), :report, 24 * 60 * 60 * 1000)
  end
end
