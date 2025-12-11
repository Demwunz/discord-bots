ExUnit.start(
  on_exit: fn ->
    Ecto.Adapters.SQL.Sandbox.stop_owner(RaffleBot.Repo)
  end
)

Application.ensure_all_started(:mox)
Mox.defmock(RaffleBot.Discord.MockApi, for: RaffleBot.Discord.Api)

Ecto.Adapters.SQL.Sandbox.mode(RaffleBot.Repo, :manual)
