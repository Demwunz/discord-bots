defmodule RaffleBot.ReleaseTest do
  use ExUnit.Case

  alias RaffleBot.Release

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(RaffleBot.Repo)
  end

  test "migrate/0 runs migrations" do
    # This is a simple test to ensure that the migrate function runs without errors.
    # A more robust test would involve checking that the database schema is updated correctly.
    assert :ok = Release.migrate()
  end
end
