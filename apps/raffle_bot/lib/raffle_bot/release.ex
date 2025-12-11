defmodule RaffleBot.Release do
  @moduledoc """
  Release tasks for the RaffleBot application.
  """

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp repos do
    Application.get_env(:raffle_bot, :ecto_repos, [])
  end
end
