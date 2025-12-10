defmodule RaffleBot.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RaffleBot.Repo,
      {RaffleBotWeb.Endpoint, []},
    ] ++ environment_specific_children()

    opts = [strategy: :one_for_one, name: RaffleBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp environment_specific_children do
    if Application.get_env(:raffle_bot, :start_discord, true) do
      [
        RaffleBot.Discord.Consumer,
        RaffleBot.Closer
      ]
    else
      []
    end
  end
end
