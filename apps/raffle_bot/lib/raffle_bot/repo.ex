defmodule RaffleBot.Repo do
  use Ecto.Repo,
    otp_app: :raffle_bot,
    adapter: Ecto.Adapters.SQLite3
end
